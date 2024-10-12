const network = await Service.import("network")
import { Item, Icon, TooltipManager, select_icon } from './utils.js'

const tooltip = new TooltipManager()

// NOTE: wired is stuck on disconnect when the interface appears when ags is already running (e.g. usb ethernet dongle is connected)
function Wired() {
  return Icon({
    label: '󰈀',
    setup: self => self.hook(network, self => {
      self.toggleClassName('yellow', false)
      if(network.wired.internet != 'connected')
        self.toggleClassName('yellow', true)
    }),
  })
}

function Wifi() {
  return Icon({
    setup: self => self.hook(network, self => {
      self.toggleClassName('red', false)
      self.toggleClassName('yellow', false)
      tooltip.set()
      if(network.wifi.enabled != true) {
        self.label = '󰤮'
        self.toggleClassName('red', true)
      }
      else if(network.wifi.internet != 'connected') {
        self.label = '󰤫'
        self.toggleClassName('yellow', true)
      }
      else {
        self.label = select_icon(['󰤯', '󰤟', '󰤢', '󰤥', '󰤨'], 0, 100, network.wifi.strength)
        tooltip.set(network.wifi.ssid)
      }
    }),
  })
}

export function Network() {
  return Item([
    Widget.Stack({
      children: {
        'wifi': Wifi(),
        'wired': Wired(),
      },
      transition: 'slide_up_down',
      transition_duration: 1000,
      shown: network.bind('primary').as(p => p || 'wifi'),
    })
  ], {
    tooltip_text: tooltip.get(),
  })
}
