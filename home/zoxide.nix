{ config, pkgs, lib, machine, opts, ... }:
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };
}
