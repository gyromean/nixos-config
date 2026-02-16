{ config, pkgs, lib, machine, opts, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      base_url = "https://papa.robotemil.net:8443";
      email = "gyro1125@gmail.com";
      pinentry = pkgs.pinentry-rofi;
    };
  };
}
