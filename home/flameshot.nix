{ config, pkgs, lib, machine, opts, ... }:
{
  services.flameshot = { # screenshoty
    enable = true;
  };
}
