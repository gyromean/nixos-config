{ config, pkgs, lib, machine, opts, ... }:
{
  programs.fzf = {
    enable = true;
    defaultCommand = "find ."; # jinak to neukazuje hidden files
    colors = {
      "fg" = "#d0d0d0";
      "bg" = "-1";
      "hl" = "#88c0d0";
      "fg+" = "#d0d0d0";
      "bg+" = "-1";
      "hl+" = "#88c0d0";
      "info" = "#616e88";
      "prompt" = "#d0d0d0";
      "pointer" = "#d0d0d0";
      "marker" = "#d0d0d0";
      "spinner" = "#d0d0d0";
      "header" = "#d0d0d0";
    };
  };
}
