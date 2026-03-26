{
  hostname = "pavelltvm";
  monitorSetup = "xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1 --off --output DP-1 --off"; # NOTE: placeholder
  polybarBrightness = "";
  polybarI3Workspaces = "";
  speakersSink = "alsa_output.pci-0000_05_00.6.HiFi__Speaker__sink";
  workspaceSetup = ''
  workspace 1:1:0 output eDP-1
  ''; # NOTE: placeholder
  defaultInterface = "";
  syncthingEnabled = false;
  wireguardEnabled = false;
}
