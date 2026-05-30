import { Item, Icon, Text, Progression, ClassManager, TooltipManager, Box, Revealer } from './utils.js'
import GLib from 'gi://GLib'

const minutes = 20
const refresh_period_s = 5
const pulsating_period_s = 4
const v = Variable(0)
const person_visible = Variable(false)

var interval_handle = null
var pulsating_handle = null
var state // idle, running, completed
var started_at = null
var completed_at = null
var completed_iterations = 0
const color_manager = new ClassManager([], ['blue', 'yellow', 'red'])
const pulsating_manager = new ClassManager([], ['pulsating-a', 'pulsating-b'])

const state_dir = `${GLib.getenv('XDG_RUNTIME_DIR')}/ags-eyetimer`
const state_path = `${state_dir}/state.json`

function now_ms() {
  return Date.now()
}

function save_state() {
  try {
    GLib.mkdir_with_parents(state_dir, 0o700)
    GLib.file_set_contents(state_path, JSON.stringify({
      state,
      started_at,
      completed_at,
      completed_iterations,
    }))
  } catch(err) {
    logError(err)
  }
}

function load_state() {
  try {
    const [ok, contents] = GLib.file_get_contents(state_path)
    if(!ok)
      return false
    const data = JSON.parse(new TextDecoder().decode(contents))
    if(!['idle', 'running', 'completed'].includes(data.state))
      return false

    state = data.state
    started_at = typeof data.started_at === 'number' ? data.started_at : null
    completed_at = typeof data.completed_at === 'number' ? data.completed_at : null
    completed_iterations = typeof data.completed_iterations === 'number' ? data.completed_iterations : 0
    return true
  } catch(err) {
    return false
  }
}

function clear_running_interval() {
  if(interval_handle !== null) {
    clearInterval(interval_handle)
    interval_handle = null
  }
}

function apply_completed_visuals() {
  person_visible.value = completed_iterations % 3 === 0
  color_manager.set(completed_iterations % 3 === 0 ? 'blue' : 'red')
  start_pulsating()
}

function apply_idle_visuals() {
  v.value = 0
  person_visible.value = false
  color_manager.set('yellow')
  stop_pulsating()
}

function refresh_running() {
  if(started_at === null)
    started_at = now_ms()
  const elapsed_minutes = Math.floor((now_ms() - started_at) / 60000)
  v.value = Math.min(elapsed_minutes, minutes)
  if(elapsed_minutes >= minutes)
    completed()
}

function restore() {
  if(!load_state()) {
    start()
    return
  }

  if(state === 'running') {
    person_visible.value = false
    color_manager.reset()
    stop_pulsating()
    refresh_running()
    if(state === 'running')
      interval_handle = setInterval(refresh_running, refresh_period_s * 1000)
  } else if(state === 'completed') {
    v.value = minutes
    apply_completed_visuals()
  } else {
    apply_idle_visuals()
  }
}

function start_pulsating() {
  const pulsating_func = () => {
    pulsating_manager.set('pulsating-a')
    setTimeout(() => {
      if(pulsating_handle !== null) {
        pulsating_manager.set('pulsating-b')
      }
    }, pulsating_period_s * 1000 / 2)
  }
  pulsating_func()
  pulsating_handle = setInterval(pulsating_func, pulsating_period_s * 1000)
}

function stop_pulsating() {
  if(pulsating_handle !== null) {
    clearInterval(pulsating_handle)
    pulsating_handle = null
    pulsating_manager.reset()
  }
}

function start() {
  clear_running_interval()
  state = 'running'
  started_at = now_ms()
  completed_at = null
  v.value = 0
  person_visible.value = false
  // tooltip_manager.set(`${minutes - v.value} min`)
  // icon.label = '󱎫',
  color_manager.reset()
  stop_pulsating()
  save_state()
  interval_handle = setInterval(refresh_running, refresh_period_s * 1000)
}

function cancel() {
  clear_running_interval()
  state = 'idle'
  started_at = null
  completed_at = null
  v.value = 0
  person_visible.value = false
  // tooltip_manager.set('Idle')
  // icon.label = '󱫎'
  color_manager.set('yellow')
  stop_pulsating()
  save_state()
}

function completed() {
  clear_running_interval()
  state = 'completed'
  started_at = null
  completed_at = now_ms()
  v.value = minutes
  completed_iterations++
  // tooltip_manager.set('Completed')
  // icon.label = '󱫌'
  apply_completed_visuals()
  save_state()
}

restore()

export function Eyetimer(bar) {
  const prog = Progression({
    value: v.bind(),
    max_value: minutes,
  })

  const icon = Icon('')
  const person = Revealer(Icon(''), {
    reveal_child: person_visible.bind(),
    transition: 'slide_right',
  })
  const icons = Box([
    icon,
    person,
  ], {
    spacing: 4,
  })

  const item = Item([
    Box([
      icons,
      prog,
    ], {
      spacing: 0,
    }),
  ], {
    // tooltip_text: tooltip_manager.get(),
  })

  // const tooltip_manager = new TooltipManager()
  bar.add_managed_item(color_manager, item)
  bar.add_managed_item(pulsating_manager, item)

  return Widget.EventBox({
    child: item,
    on_primary_click: () => {
      if(state != 'running')
        start()
    },
    on_secondary_click: () => {
      if(state != 'idle')
        cancel()
    },
  })
}
