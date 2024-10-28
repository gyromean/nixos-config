import { Item, Icon, ClassManager, TooltipManager, Progression, Box } from './utils.js'

// NOTE: this module counts on always having exactly three montiors

const monitor_to_bus = {
  0: 6,
  1: 7,
  2: 8,
}

const monitors = {}

function apply_brightness(monitor, brightness) {
  if(brightness < 0)
    brightness = 0
  if(brightness > 100)
    brightness = 100

  const bus = monitor_to_bus[monitor]
  Utils.execAsync(['ddcutil', '-t', '--bus', String(bus), 'setvcp', '10', String(brightness)])

  const data = monitors[monitor]
  data.real_var.value = brightness
  data.displayed_var.value = brightness
  data.manager.set_with_timeout('blue')
}

function apply_brightness_all(brightness) {
  for(const monitor in monitors)
    apply_brightness(monitor, brightness)
}

export function BrightnessDesktop(bar) {
  const real_var = Variable(0)
  const displayed_var = Variable(0)
  const tooltip_manager = new TooltipManager()
  const color_manager = new ClassManager([], ['blue', 'yellow'])
  monitors[bar.monitor] = {
    manager: color_manager,
    real_var,
    displayed_var,
  }

  displayed_var.connect('changed', ({ value }) => tooltip_manager.set(`${value}%`))

  const bus = monitor_to_bus[bar.monitor]
  Utils.execAsync(['ddcutil', '-t', '--bus', String(bus), 'getvcp', '10']).then(out => {
    const brightness = Math.floor(Number(out.split(' ')[3]) / 5) * 5
    displayed_var.value = brightness
    real_var.value = brightness
  })

  const icon_widget = Icon('󰃠')
  const prog = Progression({
    value: displayed_var.bind(),
  })

  color_manager.add(prog)

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

  function increase() {
    displayed_var.value = Math.min(displayed_var.value + 5, 100)
    color_manager.set('yellow')
  }

  function decrease() {
    displayed_var.value = Math.max(0, displayed_var.value - 5)
    color_manager.set('yellow')
  }

  function apply_one() {
    apply_brightness(bar.monitor, displayed_var.value)
  }

  function apply_all() {
    apply_brightness_all(displayed_var.value)
  }

  function reset() {
    displayed_var.value = real_var.value
    color_manager.reset()
  }

  const ebox = Widget.EventBox({
    child: item,
    on_scroll_up: increase,
    on_scroll_down: decrease,
    on_primary_click: apply_one,
    on_middle_click: apply_all,
    on_secondary_click: reset,
  })

  return ebox
}
