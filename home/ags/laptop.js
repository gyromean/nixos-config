import { Section, Item, Icon, Bar } from './src/utils.js'
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

function make_bar(monitor = 0) {
  return new Bar({
     monitor,
     right: [
       Eyetimer,
       Diary,
       Audio,
       Cpu,
       Memory,
       Storage,
       Network,
       Battery,
       Keyboard,
       DateModule,
     ],
   }).get_widget()
}

App.config({
  style: './style.css',
  windows: [
    make_bar(0),
  ],
})
