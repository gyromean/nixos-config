{ config, pkgs, lib, machine, opts, ... }:
{
  programs.eza = {
    enable = true;
    extraOptions = [
      "--group-directories-first"
      "--icons=auto"
    ];
    enableZshIntegration = true;
  };
}
