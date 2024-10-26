const hyprland = await Service.import("hyprland")
import { Item, Icon, Text } from './utils.js'

const lang_var = Variable('')

function set_lang() {
  Utils.execAsync(['bash', '-c', "hyprctl -j devices | jq '.keyboards[] | select(.main == true) | .active_keymap'"]).then(out => lang_var.value = out.slice(1, 3).toLowerCase())
}

set_lang()
hyprland.connect('keyboard-layout', () => set_lang())

export function Keyboard() {
  const lang_widget = Text(lang_var.bind())

  const item = Item([
    Icon('󰌓'),
    lang_widget,
  ])

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
