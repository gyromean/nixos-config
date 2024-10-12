const battery = await Service.import("battery")
import { Item, Icon } from './utils.js'

// TODO: zkontrolovat ze je battery available (je na to bind), tj. aby to nebezelo na pc (a nebo mozna spis si zase rozdelit to nastaveni baru na laptopu a na desktopu)
// TODO: dodelat, aby to ukazalo, ze se to nabiji (treba i aby to nejak poskocilo)
export function Battery() {
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

  const icon_widget = Icon({
    label: icon_char,
  })

  Utils.merge([battery.bind('percent'), battery.bind('charging'), battery.bind('charged')], (percent, charging, charged) => {
    icon_widget.toggleClassName('blue', false)
    icon_widget.toggleClassName('red', false)
    if(charging || charged)
      icon_widget.toggleClassName('blue', true)
    else if(percent <= 20)
      icon_widget.toggleClassName('red', true)
  })

  return Item([
    icon_widget,
  ], {
    class_names: ['battery'],
    tooltip_text: label,
  })
}
