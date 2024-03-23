{ config, pkgs, lib, ... }:
{
  home-manager.users.pavel = {config, ...}: {
  xdg.configFile =
    (builtins.listToAttrs
      (builtins.map
        (path:
          {
            name = path;
            value.source = (config.lib.file.mkOutOfStoreSymlink "/home/pavel/.config/nixos-config/common/dotfiles/${path}");
          }
        )
        [
          "polybar"
          "nvim/after"
          "alacritty"
          "wezterm"
          "zathura"
        ]
      )
    );
  };
}
