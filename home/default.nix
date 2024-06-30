{ config, pkgs, lib, machine, opts, ... }:
let
  linkFunc = (soft: hard:
    if opts.enableSymlinks
    then config.lib.file.mkOutOfStoreSymlink soft
    else hard
  );
in
{
  imports = [
    ./nvim.nix
  ];
  home.username = opts.username;
  home.homeDirectory = opts.homeDirectory;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.file =
  (lib.attrsets.mapAttrs'
    (dir: type: lib.nameValuePair ".config/${dir}" { source = linkFunc "${opts.configPath}/home/${dir}" ./${dir}; })
    (lib.attrsets.filterAttrs
      (dir: type: type == "directory")
      (builtins.readDir ./.)
    )
  ) // { ".config/machine" = { source = linkFunc "${opts.configPath}/hosts/${machine.hostDir}/machine" ../hosts/${machine.hostDir}/machine; }; };
}
