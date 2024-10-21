const network = await Service.import("network")
import { Item, Icon, TooltipManager, select_icon, ClassManager } from './utils.js'

const wifi_label = Variable('')
const tooltip = new TooltipManager()
const wired_color_manager = new ClassManager([], ['yellow'])
const wifi_color_manager = new ClassManager([], ['red', 'yellow'])

network.connect('changed', () => {
  if(network.wired.internet != 'connected')
    wired_color_manager.set('yellow')
  else
    wired_color_manager.reset()

  tooltip.set()
  if(network.wifi.enabled != true) {
    wifi_label.value = '󰤮'
    wifi_color_manager.set('red')
  }
  else if(network.wifi.internet != 'connected') {
    wifi_label.value = '󰤫'
    wifi_color_manager.set('yellow')
  }
  else {
    wifi_label.value = select_icon(['󰤯', '󰤟', '󰤢', '󰤥', '󰤨'], 0, 100, network.wifi.strength)
    tooltip.set(network.wifi.ssid)
    wifi_color_manager.reset()
  }

})

// NOTE: wired is stuck on disconnect when the interface appears when ags is already running (e.g. usb ethernet dongle is connected)

export function Network(bar) {
  const wired = Icon({ label: '󰈀' })
  const wifi = Icon({ label: wifi_label.bind() })

  bar.add_managed_item(wifi_color_manager, wifi)
  bar.add_managed_item(wired_color_manager, wired)

  return Item([
    Widget.Stack({
      children: {
        wifi,
        wired,
      },
      transition: 'slide_up_down',
      transition_duration: 1000,
      shown: network.bind('primary').as(p => p || 'wifi'),
    })
  ], {
    tooltip_text: tooltip.get(),
  })
}
