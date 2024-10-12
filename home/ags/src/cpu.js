import { Item, Icon, Progression, Box, TooltipManager, ClassManager } from './utils.js'

export function Cpu() {
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

  const progression_widget = Progression({
    value: usage.bind(),
  })

  const usage_manager = new TooltipManager()
  const color_manager = new ClassManager(progression_widget, ['blue', 'green', 'yellow', 'red'])

  return Item([
    Box([
      Icon({ label: '' }),
      progression_widget,
    ], {
      spacing: 5,
    })
  ], {
    tooltip_text: usage_manager.get(),
  })
}
