import { Item, Icon, ClassManager, TooltipManager, Progression, Box, Revealer, select_icon } from './utils.js'

const audio = await Service.import("audio")

const ICONS_SPEAKER = ['󰕿', '󰖀', '󰕾']
const ICON_SPEAKER_MUTED = '󰸈'
const ICON_AIRPODS = '󱡏'
const ICON_AIRPODS_MUTED = '󱡐'

const AIRPODS_MAC = '00:C5:85:68:86:3E'
const AIRPODS_SINK_PREFIX = 'bluez_output.00_C5_85_68_86_3E'

const AIRPODS_PROBE_SECONDS = 5
const AIRPODS_PROBE_INTERVAL_MS = 8000
const AIRPODS_VISIBLE_TTL_MS = 30000
const AIRPODS_SWITCH_TIMEOUT_MS = 25000
const AIRPODS_CONNECT_ATTEMPTS = 5
const AIRPODS_ERROR_FLASH_MS = 1500
const AUDIO_FEEDBACK_MS = 1000
const DEBUG_AUDIO = false

const level_var = Variable(0)
const level_var_2 = Variable(0)
const volume_overflow_visible_var = Variable(false)
const speaker_icon_var = Variable('󰕿')
const airpods_icon_var = Variable(ICON_AIRPODS)
const airpods_visible_var = Variable(false)
const airpods_active_var = Variable(false)

const tooltip_manager = new TooltipManager()
const level_color_manager = new ClassManager([], ['blue', 'yellow', 'red'])
const airpods_icon_color_manager = new ClassManager([], ['blue', 'yellow', 'red'])

let current_volume = (audio.speaker.volume || 0) * 100
let current_default_muted = audio.speaker.is_muted || false

let default_sink = null
let speaker_sink = null
let airpods_sink = null
let airpods_connected = false
let airpods_last_seen = 0

let refresh_running = false
let refresh_requested = false
let switching_output = false
let switching_target = null
let handling_airpods_drop = false
let probing_airpods = false
let airpods_error = false
let airpods_error_message = null
let airpods_error_timeout = null
let audio_feedback = null
let audio_feedback_timeout = null
let volume_initialized = false
let mute_initialized = false

function audio_log(msg) {
  if(DEBUG_AUDIO)
    print(`[audio] ${msg}`)
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

function command_repr(cmd) {
  return Array.isArray(cmd) ? cmd.join(' ') : cmd
}

function clear_timeout(handle) {
  if(handle !== null)
    clearTimeout(handle)
}

function update_level_color() {
  level_color_manager.reset()

  if(audio_feedback !== null)
    level_color_manager.set(audio_feedback)
}

function set_audio_feedback(cls) {
  audio_feedback = cls
  update_level_color()

  clear_timeout(audio_feedback_timeout)
  audio_feedback_timeout = setTimeout(() => {
    audio_feedback = null
    audio_feedback_timeout = null
    update_level_color()
  }, AUDIO_FEEDBACK_MS)
}

function update_airpods_color() {
  if(airpods_error)
    airpods_icon_color_manager.set('red')
  else if(switching_output)
    airpods_icon_color_manager.set('yellow')
  else if(airpods_active_var.value)
    airpods_icon_color_manager.set('blue')
  else
    airpods_icon_color_manager.reset()
}

function flash_airpods_error(message = 'AirPods switch failed') {
  airpods_error = true
  airpods_error_message = message
  update_airpods_visibility()
  update_airpods_color()
  update_tooltip()

  clear_timeout(airpods_error_timeout)
  airpods_error_timeout = setTimeout(() => {
    airpods_error = false
    airpods_error_message = null
    airpods_error_timeout = null
    update_airpods_visibility()
    update_airpods_color()
    update_tooltip()
  }, AIRPODS_ERROR_FLASH_MS)
}

function begin_switch(target) {
  if(switching_output) {
    audio_log(`switch to ${target} ignored: switch already running to ${switching_target}`)
    return false
  }

  airpods_error = false
  airpods_error_message = null
  clear_timeout(airpods_error_timeout)
  airpods_error_timeout = null

  switching_output = true
  switching_target = target
  update_airpods_visibility()
  update_airpods_color()
  update_tooltip()
  return true
}

function finish_switch(success, error_message = null) {
  switching_output = false
  switching_target = null

  if(!success) {
    flash_airpods_error(error_message || 'AirPods switch failed')
  } else {
    update_airpods_visibility()
    update_airpods_color()
  }

  update_tooltip()
}

async function exec_or_empty(cmd, log_failures = false) {
  try {
    return await Utils.execAsync(cmd)
  } catch(error) {
    if(log_failures)
      print(`[audio] command failed: ${command_repr(cmd)}: ${error}`)
    return ''
  }
}

async function exec_checked(cmd) {
  try {
    return await Utils.execAsync(cmd)
  } catch(error) {
    throw new Error(`command failed: ${command_repr(cmd)}: ${error}`)
  }
}

function is_airpods_sink(name) {
  return name !== null && name !== undefined && name.startsWith(AIRPODS_SINK_PREFIX)
}

function parse_sinks(output) {
  return output
    .split('\n')
    .map(line => line.trim())
    .filter(line => line.length > 0)
    .map(line => {
      const fields = line.split('\t')
      return {
        name: fields[1] || null,
        state: fields.at(-1) || '',
      }
    })
    .filter(sink => sink.name !== null)
}

function find_airpods_sink(sinks) {
  return sinks.find(sink => is_airpods_sink(sink.name)) || null
}

function sink_exists(sinks, name) {
  return name !== null && sinks.some(sink => sink.name === name)
}

function find_speaker_sink(sinks, preferred = null) {
  if(preferred !== null && !is_airpods_sink(preferred) && sink_exists(sinks, preferred))
    return preferred

  if(speaker_sink !== null && sink_exists(sinks, speaker_sink))
    return speaker_sink

  const sink = sinks.find(sink => !is_airpods_sink(sink.name))
  return sink === undefined ? null : sink.name
}

async function get_sinks() {
  return parse_sinks(await exec_or_empty(['pactl', 'list', 'sinks', 'short']))
}

async function get_default_sink() {
  const output = await exec_or_empty(['pactl', 'get-default-sink'])
  const sink = output.trim()
  return sink.length === 0 ? null : sink
}

async function get_sink_mute(sink) {
  if(sink === null)
    return null

  const output = await exec_or_empty(['pactl', 'get-sink-mute', sink])
  const match = output.match(/Mute:\s+(yes|no)/)
  if(match === null)
    return null
  return match[1] === 'yes'
}

async function set_sink_mute_checked(sink, muted) {
  if(sink === null)
    throw new Error('cannot set mute on missing sink')

  await exec_checked(['pactl', 'set-sink-mute', sink, muted ? '1' : '0'])

  const actual = await get_sink_mute(sink)
  if(actual !== muted)
    throw new Error(`sink ${sink} mute verification failed: expected=${muted}, actual=${actual}`)
}

async function set_default_sink_checked(sink) {
  if(sink === null)
    throw new Error('cannot select missing sink')

  await exec_checked(['pactl', 'set-default-sink', sink])

  const actual = await get_default_sink()
  if(actual !== sink)
    throw new Error(`default sink verification failed: expected=${sink}, actual=${actual}`)
}

async function airpods_bluez_available() {
  const output = await exec_or_empty(['bluetoothctl', 'info', AIRPODS_MAC])
  const available = output.includes(`Device ${AIRPODS_MAC}`) && !output.includes('not available')
  audio_log(`BlueZ AirPods object available=${available}`)
  return available
}

function mark_airpods_seen() {
  airpods_last_seen = Date.now()
  audio_log('AirPods seen')
  update_airpods_visibility()
}

function update_airpods_visibility() {
  const visible = airpods_connected
    || airpods_active_var.value
    || switching_output
    || airpods_error
    || (probing_airpods && airpods_visible_var.value)
    || Date.now() - airpods_last_seen < AIRPODS_VISIBLE_TTL_MS

  if(airpods_visible_var.value !== visible)
    audio_log(`AirPods visible -> ${visible}`)

  airpods_visible_var.value = visible
}

function update_tooltip() {
  const lines = [`${Math.round(current_volume)}%`]

  if(airpods_error)
    lines.push(airpods_error_message || 'AirPods switch failed')
  else if(switching_target === 'airpods')
    lines.push('Connecting AirPods')
  else if(switching_target === 'speaker')
    lines.push('Disconnecting AirPods')
  else if(airpods_active_var.value)
    lines.push('AirPods active')
  else if(airpods_visible_var.value)
    lines.push('AirPods available')

  tooltip_manager.set(lines)
}

function update_icons() {
  speaker_icon_var.value = airpods_active_var.value || current_default_muted
    ? ICON_SPEAKER_MUTED
    : select_icon(ICONS_SPEAKER, 0, 100, current_volume)

  airpods_icon_var.value = airpods_active_var.value && current_default_muted
    ? ICON_AIRPODS_MUTED
    : ICON_AIRPODS
}

async function handle_airpods_drop() {
  if(handling_airpods_drop)
    return

  handling_airpods_drop = true
  audio_log('AirPods dropped while active')

  try {
    const sinks = await get_sinks()
    const target = find_speaker_sink(sinks, default_sink)
    if(target === null) {
      audio_log('AirPods drop: no speaker sink found')
      return
    }

    speaker_sink = target
    audio_log(`AirPods drop: selecting speaker sink ${target}`)
    await set_default_sink_checked(target)
  } catch(error) {
    print(`[audio] AirPods drop handling failed: ${error}`)
  } finally {
    handling_airpods_drop = false
    schedule_refresh()
  }
}

async function refresh_audio_state() {
  const was_airpods_active = airpods_active_var.value
  const sinks = await get_sinks()
  const new_default_sink = await get_default_sink()
  const new_airpods_sink = find_airpods_sink(sinks)
  const new_airpods_connected = new_airpods_sink !== null

  default_sink = new_default_sink
  airpods_sink = new_airpods_sink === null ? null : new_airpods_sink.name
  airpods_connected = new_airpods_connected

  if(default_sink !== null && !is_airpods_sink(default_sink))
    speaker_sink = default_sink
  speaker_sink = find_speaker_sink(sinks, speaker_sink)

  if(new_airpods_connected)
    mark_airpods_seen()

  const new_airpods_active = is_airpods_sink(default_sink) && new_airpods_connected
  audio_log(`refresh: default=${default_sink}, speaker=${speaker_sink}, airpods=${airpods_sink}, airpods_connected=${airpods_connected}, airpods_state=${new_airpods_sink === null ? 'none' : new_airpods_sink.state}, active=${new_airpods_active}`)

  if(new_airpods_active && !was_airpods_active && !switching_output && speaker_sink !== null) {
    try {
      audio_log(`refresh: external AirPods activation detected; muting speaker sink ${speaker_sink}`)
      await set_sink_mute_checked(speaker_sink, true)
    } catch(error) {
      print(`[audio] external AirPods speaker mute failed: ${error}`)
    }
  }

  airpods_active_var.value = new_airpods_active
  update_airpods_visibility()

  if(was_airpods_active && !new_airpods_connected && !switching_output)
    await handle_airpods_drop()
}

function schedule_refresh() {
  if(refresh_running) {
    refresh_requested = true
    return
  }

  refresh_running = true
  refresh_audio_state()
    .catch(error => print(`[audio] refresh failed: ${error}`))
    .finally(() => {
      refresh_running = false
      if(refresh_requested) {
        refresh_requested = false
        schedule_refresh()
      }
    })
}

async function activate_airpods_sink(airpods_sink_name, target_speaker_sink) {
  if(target_speaker_sink === null)
    throw new Error('no speaker sink found to mute before AirPods switch')

  audio_log(`select AirPods: muting speaker sink ${target_speaker_sink}`)
  await set_sink_mute_checked(target_speaker_sink, true)

  audio_log(`select AirPods: selecting sink ${airpods_sink_name}`)
  await set_default_sink_checked(airpods_sink_name)

  default_sink = airpods_sink_name
  airpods_active_var.value = true
}

async function select_airpods() {
  if(!begin_switch('airpods'))
    return false

  let success = false
  let failure_message = null
  const deadline = Date.now() + AIRPODS_SWITCH_TIMEOUT_MS
  audio_log('select AirPods: starting')

  try {
    const sinks = await get_sinks()
    const current_default_sink = await get_default_sink()
    const target_speaker_sink = find_speaker_sink(sinks, current_default_sink)
    audio_log(`select AirPods: current_default=${current_default_sink}, remembered_speaker=${target_speaker_sink}, sinks=${sinks.map(s => `${s.name}:${s.state}`).join(',')}`)

    if(target_speaker_sink === null) {
      failure_message = 'No speaker sink found'
      audio_log('select AirPods: no speaker sink found')
      return false
    }

    speaker_sink = target_speaker_sink

    if(!await airpods_bluez_available()) {
      failure_message = 'AirPods not known to BlueZ'
      audio_log('select AirPods: BlueZ device object is missing; AirPods need to be paired/loaded before bluetoothctl connect can work')
      return false
    }

    for(let i = 0; i < AIRPODS_CONNECT_ATTEMPTS && Date.now() < deadline; i++) {
      const existing_sink = find_airpods_sink(await get_sinks())
      if(existing_sink !== null) {
        airpods_sink = existing_sink.name
        mark_airpods_seen()
        audio_log(`select AirPods: sink already available ${existing_sink.name}`)
        await activate_airpods_sink(existing_sink.name, target_speaker_sink)
        success = true
        return true
      }

      audio_log(`select AirPods: connect attempt ${i + 1}`)
      const connect_timeout = Math.max(1, Math.min(5, Math.ceil((deadline - Date.now()) / 1000)))
      const output = await exec_or_empty(['timeout', String(connect_timeout), 'bluetoothctl', 'connect', AIRPODS_MAC], true)
      audio_log(`select AirPods: connect attempt ${i + 1} output=${JSON.stringify(output.trim())}`)
      await sleep(700)

      const current_sinks = await get_sinks()
      const sink = find_airpods_sink(current_sinks)
      if(sink !== null) {
        airpods_sink = sink.name
        mark_airpods_seen()
        await activate_airpods_sink(sink.name, target_speaker_sink)
        success = true
        return true
      }
      audio_log(`select AirPods: AirPods sink not found after attempt ${i + 1}`)
    }
    audio_log('select AirPods: failed or timed out, AirPods sink never appeared')
    return false
  } catch(error) {
    print(`[audio] select AirPods failed: ${error}`)
    return false
  } finally {
    finish_switch(success, failure_message)
    audio_log(`select AirPods: finished, success=${success}`)
    schedule_refresh()
  }
}

async function select_speaker(disconnect_airpods = true) {
  if(!begin_switch('speaker'))
    return false

  let success = false
  audio_log(`select speaker: starting, disconnect_airpods=${disconnect_airpods}`)

  try {
    mark_airpods_seen()

    const sinks = await get_sinks()
    const target = find_speaker_sink(sinks, default_sink)
    if(target !== null) {
      speaker_sink = target
      audio_log(`select speaker: selecting sink ${target}`)
      await set_default_sink_checked(target)
      default_sink = target
      success = true
    } else {
      audio_log('select speaker: no speaker sink found')
    }

    await sleep(500)

    if(disconnect_airpods) {
      audio_log('select speaker: disconnecting AirPods')
      await exec_or_empty(['timeout', '5', 'bluetoothctl', 'disconnect', AIRPODS_MAC], true)
      mark_airpods_seen()

      // If the laptop keeps stealing AirPods back from the phone, try the
      // stronger version: run `bluetoothctl block ${AIRPODS_MAC}` after this
      // disconnect and `bluetoothctl unblock ${AIRPODS_MAC}` before connect.
    }
    return success
  } catch(error) {
    print(`[audio] select speaker failed: ${error}`)
    return false
  } finally {
    airpods_active_var.value = false
    finish_switch(success)
    audio_log(`select speaker: finished, success=${success}`)
    schedule_refresh()
  }
}

async function toggle_airpods() {
  audio_log(`toggle requested: active=${airpods_active_var.value}, connected=${airpods_connected}, visible=${airpods_visible_var.value}`)
  if(switching_output) {
    audio_log('toggle ignored: switch already running')
    return
  }

  if(airpods_active_var.value)
    await select_speaker(true)
  else
    await select_airpods()
}

async function probe_airpods(reason) {
  if(probing_airpods || switching_output || airpods_connected || airpods_active_var.value) {
    audio_log(`probe skipped: reason=${reason}, probing=${probing_airpods}, switching=${switching_output}, connected=${airpods_connected}, active=${airpods_active_var.value}`)
    update_airpods_visibility()
    return false
  }

  probing_airpods = true
  audio_log(`hcitool probe start: reason=${reason}, timeout=${AIRPODS_PROBE_SECONDS}s`)

  try {
    // hcitool probes the known paired Classic MAC without connecting audio.
    const name = (await exec_or_empty(['timeout', String(AIRPODS_PROBE_SECONDS), 'hcitool', 'name', AIRPODS_MAC], true)).trim()
    const found = name.length > 0
    audio_log(`hcitool probe finished: found=${found}, name=${JSON.stringify(name)}`)
    if(found)
      mark_airpods_seen()
    return found
  } finally {
    probing_airpods = false
    update_airpods_visibility()
  }
}

Utils.merge([audio.speaker.bind('volume')], volume => {
  current_volume = volume * 100
  level_var.value = Math.min(current_volume, 100)
  level_var_2.value = Math.max(0, Math.min(current_volume - 100, 100))
  volume_overflow_visible_var.value = current_volume > 100

  if(current_volume > 200)
    Utils.exec('pactl set-sink-volume @DEFAULT_SINK@ 200%')

  if(volume_initialized)
    set_audio_feedback(current_default_muted ? 'yellow' : 'blue')
  volume_initialized = true

  update_icons()
  update_tooltip()
})

Utils.merge([audio.speaker.bind('is_muted')], muted =>  {
  current_default_muted = muted

  if(mute_initialized)
    set_audio_feedback(muted ? 'yellow' : 'blue')
  mute_initialized = true

  update_icons()
  update_tooltip()
})

Utils.merge([airpods_active_var.bind()], active => {
  update_airpods_color()
  update_icons()
  update_tooltip()
})

Utils.merge([airpods_visible_var.bind()], () => {
  update_tooltip()
})

Utils.subprocess(
  ['pactl', 'subscribe'],
  output => {
    if(output.includes(' sink ') || output.includes('server'))
      schedule_refresh()
  },
  error => print(`[audio] pactl subscribe failed: ${error}`),
)

schedule_refresh()
probe_airpods('startup')
setInterval(() => { probe_airpods('interval') }, AIRPODS_PROBE_INTERVAL_MS)
setInterval(update_airpods_visibility, 1000)

export function Audio(bar) {
  const level_bar = Progression({ value: level_var.bind() })
  const level_bar_2 = Progression({ value: level_var_2.bind() })

  const revealer = Revealer(level_bar_2, {
    css: 'padding-right: 1px;',
    reveal_child: volume_overflow_visible_var.bind(),
  })

  const speaker_icon = Icon(speaker_icon_var.bind())
  const airpods_icon = Icon(airpods_icon_var.bind())
  const airpods_revealer = Revealer(airpods_icon, {
    reveal_child: airpods_visible_var.bind(),
    css: 'padding-left: 6px;',
  })

  bar.add_managed_item(level_color_manager, level_bar)
  bar.add_managed_item(level_color_manager, level_bar_2)
  bar.add_managed_item(airpods_icon_color_manager, airpods_icon)

  const volume_box = Box([
    level_bar,
    revealer,
  ], {
    spacing: 2,
  })

  const speaker_box = Box([
    speaker_icon,
    volume_box,
  ], {
    spacing: 4,
  })

  const item = Item([
    Box([
      speaker_box,
      airpods_revealer,
    ], {
      spacing: 0
    }),
  ], {
    tooltip_text: tooltip_manager.get(),
  })

  return Widget.EventBox({
    child: item,
    on_primary_click: _ =>  {
      set_audio_feedback(current_default_muted ? 'blue' : 'yellow')
      Utils.execAsync('pactl set-sink-mute @DEFAULT_SINK@ toggle')
    },
    on_secondary_click: _ => {
      toggle_airpods()
    },
    on_scroll_up: _ =>  {
      set_audio_feedback(current_default_muted ? 'yellow' : 'blue')
      Utils.execAsync('pactl set-sink-volume @DEFAULT_SINK@ +5%')
    },
    on_scroll_down: _ =>  {
      set_audio_feedback(current_default_muted ? 'yellow' : 'blue')
      Utils.execAsync('pactl set-sink-volume @DEFAULT_SINK@ -5%')
    },
  })
}
