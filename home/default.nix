{ config, pkgs, lib, machine, opts, ... }:

{
  imports = [
    ./nvim.nix
  ];
  home.username = opts.username;
  home.homeDirectory = opts.homeDirectory;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.file = let
    linkFunc = (dir:
      if opts.enableSymlinks
      then config.lib.file.mkOutOfStoreSymlink "${opts.configPath}/home/${dir}"
      else ./${dir}
    );
  in
  (lib.attrsets.mapAttrs'
    (dir: type: lib.nameValuePair ".config/${dir}" { source = linkFunc dir; })
    (lib.attrsets.filterAttrs
      (dir: type: type == "directory")
      (builtins.readDir ./.)
    )
  );
}
