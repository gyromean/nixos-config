{ config, pkgs, lib, machine, opts, ... }:
{
  services.picom = {
    enable = true; # bez picomu je za polybarem cerna cast kdyz nema width 100%
    vSync = true; # opravit screen tearing, viz https://unix.stackexchange.com/questions/421622/how-to-get-rid-of-background-flickering-when-switching-workspaces
    backend = "glx";
    fade = true;
    fadeDelta = 1;
    fadeSteps = [ 1 1 ];
  };
}
