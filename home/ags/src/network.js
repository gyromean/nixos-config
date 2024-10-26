const network = await Service.import("network")
import { Item, Icon, TooltipManager, select_icon, ClassManager } from './utils.js'

const wifi_label = Variable('')
const tooltip = new TooltipManager()
const wired_color_manager = new ClassManager([], ['yellow'])
const wifi_color_manager = new ClassManager([], ['red', 'yellow'])

// https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x
const get_ip = () => JSON.parse(Utils.exec('ip -j route get 1'))[0]['prefsrc']

function update() {
  const tooltip_content = []
  let connected = false

  if(network.wired.internet != 'connected')
    wired_color_manager.set('yellow')
  else {
    wired_color_manager.reset()
    connected = true
  }

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
    tooltip_content.push(network.wifi.ssid)
    wifi_color_manager.reset()
    connected = true
  }

  if(connected == false)
    tooltip_content.push('Disconnected')
  else
    tooltip_content.push(get_ip())

  tooltip.set(tooltip_content)
}

network.connect('changed', update)
update()

// NOTE: wired is stuck on disconnect when the interface appears when ags is already running (e.g. usb ethernet dongle is connected)

export function Network(bar) {
  const wired = Icon('󰈀')
  const wifi = Icon(wifi_label.bind())

  bar.add_managed_item(wifi_color_manager, wifi)
  bar.add_managed_item(wired_color_manager, wired)

  const item = Item([
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

  return Widget.EventBox({
    child: item,
    on_primary_click: _ =>  {
      Utils.execAsync(['alacritty', '-e', 'nmtui'])
    },
  })
}
