{ config, pkgs, lib, machine, opts, ... }:
{
  programs.ranger = {
    enable = true;
    extraConfig = ''
      set show_hidden true
      map <CR> move right=1
      map l eval fm.move(right=1) if fm.thisfile.is_directory else fm.edit_file(fm.thisfile.path)
    '';
  };
}
