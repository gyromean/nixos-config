{
  hostname = "pavelhp";
  monitorSetup = "xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1 --off --output DP-1 --off";
  polybarBrightness = ''python ~/.config/custom/polybar-scripts/brightness-laptop.py &'';
  polybarI3Workspaces = ''python ~/.config/custom/polybar-scripts/i3-workspaces.py "$polybar_pid" "$m" eDP-1 &'';
  speakersSink = "alsa_output.pci-0000_04_00.6.HiFi__Speaker__sink";
  workspaceSetup = ''
  workspace 1:1:0 output eDP-1
  '';
  defaultInterface = "";
  syncthingId = "E3Q2OLQ-UBCXDH2-LEC3UQU-RSVWRFN-BDJZBL7-GDXO2L3-QZG6KB6-2FWBXAZ";
}
