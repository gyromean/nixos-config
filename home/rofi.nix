{ config, pkgs, lib, machine, opts, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "alacritty";
    extraConfig = {
      kb-element-next = "Control+j";
      kb-element-prev = "Control+k";
      kb-accept-entry = "Control+m,Return,KP_Enter"; # had Control+j by default, must overwrite
      kb-remove-to-eol = ""; # had Control+k by default, must overwrite
    };
  };
}
