{ config, pkgs, lib, machine, opts, ... }:
{
  programs.tmux = {
    enable = true;
  };
}
