const hyprland = await Service.import("hyprland")
import { Item, Icon, Text } from './utils.js'

export function Keyboard() {
  const lang_widget = Text('lmao')

  function set_lang() {
    Utils.execAsync(['bash', '-c', "hyprctl -j devices | jq '.keyboards[] | select(.main == true) | .active_keymap'"]).then(out => lang_widget.label = out.slice(1, 3).toLowerCase())
  }

  set_lang()
  hyprland.connect('keyboard-layout', () => set_lang())

  return Item([
    Icon({
      label: '󰌓',
    }),
    lang_widget,
  ])
}
