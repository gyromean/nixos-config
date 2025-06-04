{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/configuration.nix
    ./hardware-configuration.nix
  ];
}
