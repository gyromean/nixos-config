{ config, pkgs, lib, ... }@inputs:

{
  imports = [
    ../../modules/configuration.nix
    ./hardware-configuration.nix
  ];

  # 6.18.32 regressed this laptop's MediaTek Bluetooth init in btmtk:
  # "Failed to send wmt func ctrl (-22)". Use unstable's 6.18.x until the
  # nixos-25.11 kernel carries the too-short WMT FUNC_CTRL event fix.
  boot.kernelPackages = lib.mkForce inputs.nixpkgs-unstable.legacyPackages."${pkgs.stdenv.hostPlatform.system}".linuxPackages_6_18;

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
