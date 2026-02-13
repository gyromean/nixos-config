import { Item, Icon, Text, Progression, ClassManager, TooltipManager, Box } from './utils.js'

const minutes = 20
const pulsating_period_s = 4
const v = Variable(0)

var interval_handle = null
var pulsating_handle = null
var state // idle, running, completed
const color_manager = new ClassManager([], ['yellow', 'red'])
const pulsating_manager = new ClassManager([], ['pulsating-a', 'pulsating-b'])
start()

function start_pulsating() {
  const pulsating_func = () => {
    pulsating_manager.set('pulsating-a')
    setTimeout(() => {
      if(pulsating_handle !== null) {
        pulsating_manager.set('pulsating-b')
      }
    }, pulsating_period_s * 1000 / 2)
  }
  pulsating_func()
  pulsating_handle = setInterval(pulsating_func, pulsating_period_s * 1000)
}

function stop_pulsating() {
  if(pulsating_handle !== null) {
    clearInterval(pulsating_handle)
    pulsating_handle = null
    pulsating_manager.reset()
  }
}

function start() {
  state = 'running'
  v.value = 0
  // tooltip_manager.set(`${minutes - v.value} min`)
  // icon.label = '󱎫',
  color_manager.reset()
  stop_pulsating()
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
  stop_pulsating()
}

function completed() {
  state = 'completed'
  // tooltip_manager.set('Completed')
  // icon.label = '󱫌'
  color_manager.set('red')
  start_pulsating()
}

export function Eyetimer(bar) {
  const prog = Progression({
    value: v.bind(),
    max_value: minutes,
  })

  const icon = Icon('')

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

  // const tooltip_manager = new TooltipManager()
  bar.add_managed_item(color_manager, item)
  bar.add_managed_item(pulsating_manager, item)

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
