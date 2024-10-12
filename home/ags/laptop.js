import { Section, Item, Icon } from './src/utils.js'
import { Battery } from './src/battery.js'
import { DateModule } from './src/date.js'
import { Audio } from './src/audio.js'
import { Network } from './src/network.js'
import { Keyboard } from './src/keyboard.js'
import { Cpu } from './src/cpu.js'
import { Memory } from './src/memory.js'
import { Storage } from './src/storage.js'
import { Eyetimer } from './src/eyetimer.js'
import { Diary } from './src/diary.js'

Utils.monitorFile(
  '/home/pavel/.config/ags/style.css',
  function() {
    App.resetCss()
    App.applyCss('/home/pavel/.config/ags/style.css')
  }
)

function Left() {
  return Section([
  ], { hpack: 'start' })
}

function Right() {
  return Section([
    Eyetimer(),
    Diary(),
    Audio(),
    Cpu(),
    Memory(),
    Storage(),
    Network(),
    Battery(),
    Keyboard(),
    DateModule(),
  ], { hpack: 'end' })
}

function Bar(monitor = 0) {
  return Widget.Window({
    name: `bar-${monitor}`,
    class_name: 'bar',
    monitor,
    anchor: ['top', 'left', 'right'],
    exclusivity: 'exclusive',
    child: Widget.CenterBox({
      start_widget: Left(),
      end_widget: Right(),
    }),
  })
}

App.config({
  style: './style.css',
  windows: [
    Bar(0),
  ],
})
