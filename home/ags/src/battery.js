const battery = await Service.import("battery")
import { Item, Icon, ClassManager } from './utils.js'

const label = battery.bind('percent').as(percent => ` ${percent}% `)
const icon_char = battery.bind('percent').as(percent => {
  let val
  if(percent <= 0)
    val = 0
  else if(percent >= 100)
    val = 9
  else
    val = Math.floor(percent / 10)
  return ['󰁺', '󰁻', '󰁼', '󰁽', '󰁾', '󰁿', '󰂀', '󰂁', '󰂂', '󰁹'][val]
})

const color_manager = new ClassManager([], ['blue', 'red'])

Utils.merge([battery.bind('percent'), battery.bind('charging'), battery.bind('charged')], (percent, charging, charged) => {
  if(charging || charged)
    color_manager.set('blue')
  else if(percent <= 20)
    color_manager.set('red')
  else
    color_manager.reset()
})

export function Battery(bar) {
  const icon_widget = Icon({
    label: icon_char,
  })

  const item = Item([
    icon_widget,
  ], {
    class_names: ['battery'],
    tooltip_text: label,
  })

  bar.add_managed_item(color_manager, item)

  return item
}
