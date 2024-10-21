import { Item, Icon, Progression, Box, TooltipManager, ClassManager, repr_memory } from './utils.js'

export function Memory() {
  const usage = Variable(0, {
    poll: [1000, 'free -b', out => {
      out = out.split('\n').find(line => line.includes('Mem:'))

      let out_splitted = out.split(/\s+/)
      let mem_total = Number(out_splitted[1])
      let mem_used = Number(out_splitted[2])
      let percentage = Math.round(100 * mem_used / mem_total)

      let mem_used_repr = repr_memory(mem_used)

      usage_manager.set(mem_used_repr)

      if(percentage <= 60)
        color_manager.reset()
      else if(percentage <= 80)
        color_manager.set('yellow')
      else
        color_manager.set('red')

      return percentage
    }],
  })

  const progression_widget = Progression({
    value: usage.bind(),
  })

  const usage_manager = new TooltipManager()
  const color_manager = new ClassManager(progression_widget, ['blue', 'green', 'yellow', 'red'])

  return Item([
    Box([
      Icon({ label: '' }),
      progression_widget,
    ], {
      spacing: 5,
    })
  ], {
    tooltip_text: usage_manager.get(),
  })
}