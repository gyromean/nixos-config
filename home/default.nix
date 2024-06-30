{ config, pkgs, lib, machine, opts, ... }:

{
  imports = [
    ./nvim.nix
  ];
  home.username = opts.username;
  home.homeDirectory = opts.homeDirectory;


  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  # home.file =
  # (lib.attrsets.mapAttrs'
  #   (dir: type: lib.nameValuePair ".config/${dir}" { source = ./${dir}; })
  #   (lib.attrsets.filterAttrs
  #     (dir: type: type == "directory")
  #     (builtins.readDir ./.)
  #   )
  # ) // { ".config/asdfbruh" = { text = builtins.toPath ./polybar/config.ini + "\n" + builtins.toPath ../hosts/desktop/default.nix; }; };

  home.file =
  (lib.attrsets.mapAttrs'
    (dir: type: lib.nameValuePair ".config/${dir}" { source = config.lib.file.mkOutOfStoreSymlink "${opts.configPath}/home/${dir}"; })
    (lib.attrsets.filterAttrs
      (dir: type: type == "directory")
      (builtins.readDir ./.)
    )
  ) // { ".config/asdfbruh" = { text = builtins.toPath ./polybar/config.ini + "\n" + builtins.toPath ../hosts/desktop/default.nix; }; };
}
