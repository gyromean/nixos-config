import { Item, Icon, ClassManager, TooltipManager, Progression, Box, Revealer, socket } from './utils.js'

const brightness_max = Number(Utils.exec('brightnessctl max'))
const brightness_var = Variable(get_brightness())

const color_manager = new ClassManager([], ['blue'])
const tooltip_manager = new TooltipManager()

function get_brightness(round = true) {
  const percentage = Number(Utils.exec('brightnessctl get')) / brightness_max * 100
  if(round == false)
    return percentage
  return Math.floor(percentage / 5) * 5
}

function set_brightness(percentage) {
  if(percentage < 0)
    percentage = 0
  if(percentage > 100)
    percentage = 100
  brightness_var.value = percentage
  Utils.execAsync(`brightnessctl set ${percentage}%`)
  tooltip_manager.set(`${percentage}%`)
  color_manager.set_with_timeout('blue')
}

const increase = () => set_brightness(brightness_var.value + 5)
const decrease = () => set_brightness(brightness_var.value - 5)

socket.add('brightness', msg => {
  switch(msg) {
    case 'increase':
      increase()
      break
    case 'decrease':
      decrease()
      break
  }
})

set_brightness(brightness_var.value) // to setup tooltip manager

export function BrightnessLaptop(bar) {
  const icon_widget = Icon('󰃠')
  const prog = Progression({
    value: brightness_var.bind(),
  })

  bar.add_managed_item(color_manager, prog)

  const item = Item([
    Box([
      icon_widget,
      prog,
    ], {
      spacing: 4,
    }),
  ], {
    tooltip_text: tooltip_manager.get(),
  })

  const ebox = Widget.EventBox({
    child: item,
    on_scroll_up: () => increase(),
    on_scroll_down: () => decrease(),
  })

  return ebox
}
