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
        (lib.attrsets.mapAttrsToList
          (path: type: path)
          (lib.attrsets.filterAttrs
            (name: type: type == "directory")
            (builtins.readDir /home/pavel/.config/nixos-config/common/dotfiles)
          )
        )
      )
    );
  };
}
