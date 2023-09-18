{
  hostname = "pavelpc";
  monitorSetup = "xrandr --dpi 96 --output HDMI-0 --off --output DP-0 --mode 2560x1440 --pos 0x0 --rotate normal --rate 165 --output DP-1 --off --output DP-2 --mode 2560x1440 --pos 5120x0 --rotate normal --rate 165 --output DP-3 --off --output DP-4 --mode 2560x1440 --pos 2560x0 --rotate normal --rate 165 --output DP-5 --off";
  polybarBrightness = ''python ~/.config/nixos-config/common/polybar-scripts/brightness-desktop.py "$!" "$m" &'';
  workspaceSetup = ''
  workspace 1:1 output DP-0
  workspace 1:2 output DP-4
  workspace 1:3 output DP-2
  '';
}
