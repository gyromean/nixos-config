const audio = await Service.import("audio")
import { Item, Icon, ClassManager, TooltipManager, Progression, Box, Revealer } from './utils.js'

// DONE: dodelat zase hover, ktery mi rekne presny procenta
// DONE: kdyz budu mit hlasitost vic jak 100%, tak 1) u toho levelbaru to manualne nastavit na min(val, 100), jinak to prestane byt rounded nahore, a 2) vysunout vpravo dalsi levelbar, ktery bude merit 100-200, atd.

const level_var = Variable(0)
const level_var_2 = Variable(0)
const revealer_var = Variable(false)
const icon_var = Variable('󰕿')
var is_muted = audio.speaker.is_muted || false

const tooltip_manager = new TooltipManager()
const color_manager = new ClassManager([], ['blue', 'green', 'yellow', 'red'])

Utils.merge([audio.speaker.bind('volume')], (volume) => {
  volume *= 100
  level_var.value = Math.min(volume, 100)
  level_var_2.value = Math.max(0, Math.min(volume - 100, 100))
  tooltip_manager.set(Math.round(volume) + '%')
  revealer_var.value = volume > 100
  if(volume <= 200)
    color_manager.set_with_timeout(is_muted ? 'yellow' : 'blue')
  else
    Utils.exec('pactl set-sink-volume @DEFAULT_SINK@ 200%')
})

Utils.merge([audio.speaker.bind('is_muted')], (m) =>  {
  is_muted = m
  color_manager.set_with_timeout(is_muted ? 'yellow' : 'blue')
  icon_var.value = is_muted ? '󰸈' : '󰕿'
})

export function Audio(bar) {
  const level_bar = Progression({ value: level_var.bind() })
  const level_bar_2 = Progression({ value: level_var_2.bind() })

  const revealer = Revealer(level_bar_2, {
    css: 'padding-right: 1px;',
    reveal_child: revealer_var.bind(),
  })

  const icon_widget = Icon({ label: icon_var.bind() })

  bar.add_managed_item(color_manager, level_bar)
  bar.add_managed_item(color_manager, level_bar_2)

  return Item([
    Box([
      icon_widget,
      level_bar,
      revealer,
    ], {
      spacing: 2
    }),
  ], {
    tooltip_text: tooltip_manager.get(),
  })
}

/*
// TODO: dodelat, aby ten revealer byl vlastne box revealeru a jeste jedny sousedni veci (v tomhle pripade tech procent), protoze jinak mi tam Item prida blank mezeru navic; kdyz bude revealed, tak mu dat jeste nejakej padding, aby to revealnuty vypadalo s mezerou spravne (iirc kdyz tam dam padding rovnou do css, tak se projevi, jen kdyz je to revealed, takze by to melo fungovat out of the box)
export function Audio() {
  // const icon_bt = Widget.Label({
  //   label: '󱡏',
  //   class_name: 'icon',
  // })
  const icon_bt = Icon({
    label: '󱡏',
  })

  const rev = Widget.Revealer({
    revealChild: false,
    transitionDuration: 1000,
    // transitionDuration: 500,
    transition: 'slide_right',
    child: icon_bt,
  })

  const icon_speaker = Icon({
    label: '󰖀',
  })

  const item = Item([
    icon_speaker,
    Widget.Label({
      label: '35%',
    }),
    rev,
  ], { class_names: ['audio'] })

  return Widget.EventBox({
    child: item,
    on_hover: (e) => { rev.reveal_child = true; icon_speaker.toggleClassName('blue', true); print('yes') },
    on_hover_lost: (e) => { rev.reveal_child = false; icon_speaker.toggleClassName('blue', false); print('no') },
  })
}
*/
