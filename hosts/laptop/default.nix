{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/configuration.nix
    ./hardware-configuration.nix
  ];

  services.fprintd.enable = true;

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
