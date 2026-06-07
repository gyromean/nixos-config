const hyprland = await Service.import("hyprland")
import { Item, Icon, Text, Revealer, ClassManager, socket, Box } from './utils.js'

const lang_var = Variable('')
const dictation_state_var = Variable('idle')
const dictation_color_manager = new ClassManager([], ['blue'])

function set_lang() {
  Utils.execAsync(['bash', '-c', "hyprctl -j devices | jq -r '.keyboards[] | select(.main == true) | .active_keymap'"]).then(out => {
    if(out != "error")
      lang_var.value = out.slice(0, 2).toLowerCase()
  })
}

set_lang()
hyprland.connect('keyboard-layout', () => set_lang())

socket.add('dictation', state => {
  state = state.trim()
  dictation_state_var.value = state

  if(state == 'listening')
    dictation_color_manager.set('blue')
  else
    dictation_color_manager.reset()
})

export function Keyboard(bar) {
  const lang_widget = Text(lang_var.bind())
  const dictation_icon = Icon('󰍬')
  const dictation_rev = Revealer(dictation_icon, {
    reveal_child: dictation_state_var.bind().as(state => state != 'idle' && state != 'done'),
    transition: 'slide_right',
  })

  const item = Item([Box([
    dictation_rev,
    Icon('󰌓'),
    lang_widget,
  ], {
    spacing: 4,
  })])

  bar.add_managed_item(dictation_color_manager, dictation_icon)

  return Widget.EventBox({
    child: item,
    on_primary_click: _ => {
      Utils.execAsync(['hyprctl', 'devices', '-j']).then(out => {
        const keyboard_name = JSON.parse(out)['keyboards']
          .filter(({ main }) => main == true)
          .map(({ name }) => name)[0]
        Utils.execAsync(['hyprctl', 'switchxkblayout', keyboard_name, 'next'])
      })
    },
  })
}
