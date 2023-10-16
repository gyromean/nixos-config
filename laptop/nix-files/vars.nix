{
  hostname = "pavellt";
  monitorSetup = "xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1 --off --output DP-1 --off";
  polybarBrightness = ''python ~/.config/nixos-config/common/polybar-scripts/brightness-laptop.py &'';
  polybarI3Workspaces = ''python ~/.config/nixos-config/common/polybar-scripts/i3-workspaces.py "$polybar_pid" "$m" eDP-1 &'';
  workspaceSetup = ''
  workspace 1:1:0 output eDP-1
  '';
}
