{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/configuration.nix
    ./hardware-configuration.nix
  ];

  services.fprintd.enable = true;
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  # Zram swap
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Add swap
  swapDevices = [
    { device = "/swapfile"; size = 16384; }
  ];
}
