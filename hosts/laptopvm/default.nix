{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/configuration.nix
    ./hardware-configuration.nix
  ];

  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    device = lib.mkForce "/dev/sda";
    efiSupport = lib.mkForce false;
  };

  services.desktopManager.gnome.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
