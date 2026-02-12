{ config, pkgs, lib, machine, opts, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "alacritty";
  };
}
