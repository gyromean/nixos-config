{ config, pkgs, lib, machine, opts, ... }:
{
  programs.rofi = {
    enable = true;
    terminal = "alacritty";
  };
}
