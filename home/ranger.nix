{ config, pkgs, lib, machine, opts, ... }:
{
  xdg.configFile."ranger/rc.conf".text = ''
set show_hidden true
'';
}
