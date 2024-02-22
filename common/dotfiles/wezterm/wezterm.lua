local wezterm = require 'wezterm'
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config = {
  color_scheme = 'nord',
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  enable_tab_bar = false,
  font = wezterm.font('monospace'),
  font_size = 12,
  audible_bell = "Disabled",
  keys = {
    { key = 'd', mods = 'SHIFT|CTRL', action = wezterm.action.QuickSelect },
  },
}

return config
