{ config, pkgs, lib, machine, opts, ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "nord";
      vim_keys = true;
      update_ms = 500;
    };
  };
}
