import { Item, Icon, Progression, Box, TooltipManager, repr_memory } from './utils.js'

const usage_manager = new TooltipManager()

const usage = Variable(0, {
  poll: [1000, 'df', out => {
    out = out.split('\n').find(line => line.endsWith(' /'))
    let out_splitted = out.split(/\s+/)
    let percentage = Number(out_splitted[4].slice(0, -1))

    let free_mem = Number(out_splitted[3]) * 1024
    let free_mem_repr = repr_memory(free_mem)
    usage_manager.set(`${free_mem_repr} free`)

    return percentage
  }],
})

export function Storage() {
  const progression_widget = Progression({
    value: usage.bind(),
  })

  const item = Item([
    Box([
      Icon('󰋊'),
      progression_widget,
    ], {
      spacing: 4,
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
