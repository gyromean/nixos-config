{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/configuration.nix
    ./hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
    ];

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  boot.kernelModules = [ "nvidia" ];

  fileSystems."/home/pavel/harddrive" = {
    device = "/dev/disk/by-uuid/a8d558a8-007b-4852-8169-05f56e9dfa06";
  };
}
