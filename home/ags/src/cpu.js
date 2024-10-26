import { Item, Icon, Progression, Box, TooltipManager, ClassManager } from './utils.js'

const usage = Variable(0, {
  listen: [['bash', '-c', 'mpstat 1 | fgrep --line-buffered all'], out => {
    let out_splitted = out.split(/\s+/)
    let user_time = Number(out_splitted[2])
    let sys_time = Number(out_splitted[4])
    let combined_time = Math.round(user_time + sys_time)

    usage_manager.set(`${combined_time}%`)

    if(combined_time <= 60)
      color_manager.reset()
    else if(combined_time <= 80)
      color_manager.set('yellow')
    else
      color_manager.set('red')

    return combined_time
  }],
})

const usage_manager = new TooltipManager()
const color_manager = new ClassManager([], ['blue', 'green', 'yellow', 'red'])

export function Cpu(bar) {

  const progression_widget = Progression({
    value: usage.bind(),
  })

  bar.add_managed_item(color_manager, progression_widget)

  const item = Item([
    Box([
      Icon({ label: '' }),
      progression_widget,
    ], {
      spacing: 5,
    })
  ], {
    tooltip_text: usage_manager.get(),
  })

  return Widget.EventBox({
    child: item,
    on_primary_click: _ =>  {
      Utils.execAsync(['alacritty', '-e', 'btop'])
    },
  })
}
