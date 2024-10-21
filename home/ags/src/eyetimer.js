import { Item, Icon, Text, Progression, ClassManager, TooltipManager, Box } from './utils.js'

const minutes = 20
const v = Variable(0)

export function Eyetimer() {
  const prog = Progression({
    value: v.bind(),
    max_value: minutes,
  })

  const icon = Icon({
    // label: '󱎫',
    // label: '󱎴',
    // label: '󰔱',
    // label: '󱇛',
    // label: '󰞏',
    // label: '',
    label: '',
    // label: '󱁕',
  })

  const item = Item([
    Box([
      icon,
      prog,
    ], {
      spacing: 4,
    }),
  ], {
    // tooltip_text: tooltip_manager.get(),
  })

  // TODO: az to budu predelavat na multi monitor, tak tohle asi udelat jako globalni promennou atd.
  var interval_handle = null
  var state // idle, running, completed
  const color_manager = new ClassManager(item, ['yellow', 'red'])
  // const tooltip_manager = new TooltipManager()
  start()

  function start() {
    state = 'running'
    v.value = 0
    // tooltip_manager.set(`${minutes - v.value} min`)
    // icon.label = '󱎫',
    color_manager.reset()
    interval_handle = setInterval(() => {
      v.value++
      // tooltip_manager.set(`${minutes - v.value} min`)
      if(v.value == minutes) {
        clearInterval(interval_handle)
        completed()
      }
    }, 60000)
  }

  function cancel() {
    state = 'idle'
    v.value = 0
    // tooltip_manager.set('Idle')
    // icon.label = '󱫎'
    color_manager.set('yellow')
    if(interval_handle !== null)
      clearInterval(interval_handle)
  }

  function completed() {
    state = 'completed'
    // tooltip_manager.set('Completed')
    // icon.label = '󱫌'
    color_manager.set('red')
  }


  return Widget.EventBox({
    child: item,
    on_primary_click: () => {
      if(state != 'running')
        start()
    },
    on_secondary_click: () => {
      if(state != 'idle')
        cancel()
    },
  })
}