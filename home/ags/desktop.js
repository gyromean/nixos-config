import { Section, Item, Icon, Bar } from './src/utils.js'
import { DateModule } from './src/date.js'
import { Audio } from './src/audio.js'
import { Network } from './src/network.js'
import { Keyboard } from './src/keyboard.js'
import { Cpu } from './src/cpu.js'
import { Memory } from './src/memory.js'
import { Storage } from './src/storage.js'
import { Eyetimer } from './src/eyetimer.js'
import { Diary } from './src/diary.js'
import { Workspaces } from './src/workspaces.js'
import { WorkspaceGroups } from './src/workspace-groups.js'
import { ActionDisplay } from './src/action-display.js'
import { BrightnessDesktop } from './src/brightness-desktop.js'
import { Macrotracker } from './src/macrotracker.js'
import { physical_monitor_bindings, physical_monitor_signature } from './src/monitors.js'

const hyprland = await Service.import('hyprland')
let monitor_signature = null
let restart_timeout = null
let restart_requested = false

Utils.monitorFile(
  '/home/pavel/.config/ags/style.css',
  function() {
    App.resetCss()
    App.applyCss('/home/pavel/.config/ags/style.css')
  }
)

function make_bar(binding) {
  return new Bar({
    monitor: binding.monitor,
    hypr_monitor_id: binding.hypr_monitor_id,
    left: [
      Workspaces,
      WorkspaceGroups,
    ],
    center: [
      ActionDisplay,
    ],
    right: [
      Eyetimer,
      Diary,
      Macrotracker,
      BrightnessDesktop,
      Audio,
      Cpu,
      Memory,
      Storage,
      Network,
      Keyboard,
      DateModule,
    ],
  })
}

function restart_bar(reason) {
  if(restart_requested)
    return
  restart_requested = true
  print(`[bar] restart: ${reason}`)
  Utils.execAsync([
    'bash',
    '-lc',
    'setsid bash -lc \'sleep 0.7; exec ags1 -c "/home/pavel/.config/ags/desktop.js" -b bar > "${XDG_RUNTIME_DIR:-/tmp}/ags-bar.log" 2>&1\' >/dev/null 2>&1 &',
  ]).catch(logError)
  setTimeout(() => App.quit(), 50)
}

function schedule_topology_check() {
  if(restart_timeout !== null)
    clearTimeout(restart_timeout)
  restart_timeout = setTimeout(() => {
    restart_timeout = null
    const next_signature = physical_monitor_signature(hyprland)
    if(next_signature !== monitor_signature)
      restart_bar(`${monitor_signature} -> ${next_signature}`)
  }, 500)
}

monitor_signature = physical_monitor_signature(hyprland)
const monitor_bindings = physical_monitor_bindings(hyprland)
for(const binding of monitor_bindings)
  print(`[bar] initial monitor ${binding.hypr_monitor_id} ${binding.name} -> gdk ${binding.monitor}`)

App.config({
  style: './style.css',
  windows: monitor_bindings.map(binding => make_bar(binding).get_widget()),
  onConfigParsed: () => {
    hyprland.connect('changed', schedule_topology_check)
  },
})
