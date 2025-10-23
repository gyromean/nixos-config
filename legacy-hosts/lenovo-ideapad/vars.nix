{
  hostname = "pavellt";
  monitorSetup = "xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1 --off --output DP-1 --off";
  polybarBrightness = ''python ~/.config/custom/polybar-scripts/brightness-laptop.py &'';
  polybarI3Workspaces = ''python ~/.config/custom/polybar-scripts/i3-workspaces.py "$polybar_pid" "$m" eDP-1 &'';
  speakersSink = "alsa_output.pci-0000_03_00.6.analog-stereo";
  workspaceSetup = ''
  workspace 1:1:0 output eDP-1
  '';
  defaultInterface = "wlp1s0";
  syncthingId = "PAWMAPS-NBWXQMH-GYQF2UU-JRKHTEP-4ENC3BN-FNJYRUJ-QZ2HO5H-DBL4DAG";
}
