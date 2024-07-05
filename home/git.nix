{ config, pkgs, lib, machine, opts, ... }:
{
  programs.git = {
    enable = true;
    aliases = {
      st = "status";
      ci = "commit";
      co = "checkout";
      br = "branch";
      ll = "log --oneline --graph --all --decorate";
      last = "log --oneline --graph --decorate HEAD^..HEAD";
      d = "diff";
      dc = "diff --cached";
      cim = "commit -m";
      ap = "add -p";
      au = "add -u";
    };
    extraConfig = {
      user = {
        email = "gyro1125@gmail.com";
        name = "Pavel Holy";
      };
      diff = {
        algorithm = "patience";
      };
    };
  };
}
