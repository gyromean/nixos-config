const hyprland = await Service.import("hyprland")
import { Item, Icon, Text, socket, merge, Box } from './utils.js'

class ActionDisplayClass {
  constructor() {
    this.#reset_children()
    this.shown_var = Variable('reset')
    socket.add('action-display', msg => {
      switch(msg) {
        case 'reset':
          submap()
          this.reset()
          break
      }
    })
  }
  add_items(namespace, items) {
    let namespaced_items = {}
    for(let key in items)
      namespaced_items[`${namespace}::${key}`] = items[key]
    this.children = merge(this.children, namespaced_items)
  }
  make_widget() {
    const stack = Widget.Stack({
      children: this.children,
      transition: 'slide_up',
      transition_duration: 500,
      shown: this.shown_var.bind(),
    })
    this.#reset_children()
    return Item([
      stack,
    ])
  }
  show(namespace, item) {
    this.shown_var.value = `${namespace}::${item}`
  }
  reset() {
    this.shown_var.value = 'reset'
  }
  #reset_children() {
    this.children = {
      'reset': Text(''), // empty
    }
  }
}

const action_display = new ActionDisplayClass()

function IconLabel(icon, label, callback=null) {
  const ret = Icon(icon, {
    tooltip_text: ` ${label} `,
  })
  if(callback === null)
    return ret
  return Widget.EventBox({
    child: ret,
    on_primary_click: callback,
  })
}

function IconBox(icons, opts = {}) {
  return Box(icons, merge({
    spacing: 24,
    hpack: 'center',
  }, opts))
}

function submap(s = 'reset') {
  hyprland.messageAsync(`dispatch submap ${s}`)
}

export function ActionDisplay() {
  action_display.add_items('screenshot', screenshot.generate())
  action_display.add_items('powermenu', powermenu.generate())
  return action_display.make_widget()
}

// ----- SCREENSHOT -----

class ScreenshotClass {
  constructor() {
    this.cb = {
      'init': msg => {
        submap('screenshot_type')
        action_display.show('screenshot', 'type')
      },

      'type': msg => {
        submap('screenshot_save')
        action_display.show('screenshot', 'save')
        this.type = msg
      },

      'save': msg => {
        submap()
        this.save = msg
        Utils.execAsync(['grimblast', this.save, this.type])
        action_display.reset()
      },
    }
    for(let callback in this.cb)
      socket.add(`screenshot::${callback}`, this.cb[callback])
  }
  generate() {
    return {
      'type': IconBox([
        IconLabel('󰒅', 'a', () => this.cb.type('area')), // area
        IconLabel('󰍹', 's', () => this.cb.type('output')), // screen
        IconLabel('󰍺', 'm', () => this.cb.type('screen')), // multiple
      ]),
      'save': IconBox([
        IconLabel('', 'c', () => this.cb.save('copy')), // copy (copy)
        IconLabel('󰠘', 's', () => this.cb.save('save')), // save (save)
        IconLabel('󰽄', 'b', () => this.cb.save('copysave')), // both (copysave)
      ]),
    }
  }
}

const screenshot = new ScreenshotClass()

// ----- POWERMENU -----

class PowermenuClass {
  constructor() {
    this.cb = {
      'init': msg => {
        submap('powermenu')
        action_display.show('powermenu', 'action')
      },

      'action': msg => {
        submap()
        action_display.reset()
        switch(msg) {
          case 'shutdown':
            Utils.execAsync('systemctl poweroff')
            break
          case 'restart':
            Utils.execAsync('systemctl reboot')
            break
          case 'sleep':
            Utils.execAsync(['bash', '-c', 'systemctl suspend && hyprlock']) // delay for hyprlock animation to finish
            break
          case 'logout':
            hyprland.messageAsync('dispatch exit')
            break
          case 'lock':
            Utils.execAsync('hyprlock')
            break
        }
      },
    }
    for(let callback in this.cb)
      socket.add(`powermenu::${callback}`, this.cb[callback])
  }
  generate() {
    return {
      'action': IconBox([
        IconLabel('⏻', 's', () => this.cb.action('shutdown')), // [s]hutdown
        IconLabel('', 'r', () => this.cb.action('restart')), // [r]estart
        IconLabel('󰤄', 'e', () => this.cb.action('sleep')), // sl[e]ep
        IconLabel('󰍃', 'o', () => this.cb.action('logout')), // log[o]ut
        IconLabel('', 'l', () => this.cb.action('lock')), // [l]ock
      ]),
    }
  }
}

const powermenu = new PowermenuClass()
