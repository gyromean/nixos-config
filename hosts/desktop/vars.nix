{
  hostname = "pavelpc";
  monitorSetup = "xrandr --dpi 96 --output HDMI-0 --off --output DP-0 --mode 2560x1440 --pos 0x0 --rotate normal --rate 165 --output DP-1 --off --output DP-2 --mode 2560x1440 --pos 5120x0 --rotate normal --rate 165 --output DP-3 --off --output DP-4 --mode 2560x1440 --pos 2560x0 --rotate normal --rate 165 --output DP-5 --off";
  polybarBrightness = ''python ~/.config/nixos-config/common/polybar-scripts/brightness-desktop.py "$polybar_pid" "$m" &'';
  polybarI3Workspaces = ''python ~/.config/nixos-config/common/polybar-scripts/i3-workspaces.py "$polybar_pid" "$m" DP-0 DP-4 DP-2 &'';
  workspaceSetup = ''
  workspace 1:1:0 output DP-0
  workspace 1:2:0 output DP-4
  workspace 1:3:0 output DP-2
  '';
  defaultInterface = "enp8s0";
  syncthingId = "UDT2VMQ-ZO3ADZK-3S4PKYD-KACHGD2-E4H7S6C-CNIN7GZ-OEFD25L-X3IR3QN";
}
