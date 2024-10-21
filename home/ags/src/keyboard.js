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

  return Item([
    Icon({
      label: '󰌓',
    }),
    lang_widget,
  ])
}
