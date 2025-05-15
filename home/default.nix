{ config, pkgs, lib, machine, opts, ... }@inputs:
let
  linkFunc = (soft: hard:
    if opts.enableSymlinks
    then config.lib.file.mkOutOfStoreSymlink soft
    else hard
  );
in
{
  # import all .nix files from this directory except default.nix
  imports =
    (lib.mapAttrsToList
      (name: type: (import ./${name} (inputs // { inherit linkFunc; })))
      (lib.attrsets.filterAttrs
        (name: type: type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
        (builtins.readDir ./.)
      )
    );

  home.username = opts.username;
  home.homeDirectory = opts.homeDirectory;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  # link config files and machine config files
  home.file =
    (lib.attrsets.mapAttrs'
      (dir: type: lib.nameValuePair ".config/${dir}" { source = linkFunc "${opts.configPath}/home/${dir}" ./${dir}; })
      (lib.attrsets.filterAttrs
        (dir: type: type == "directory" && dir != "nolink")
        (builtins.readDir ./.)
      )
    ) // { ".config/machine" = { source = linkFunc "${opts.configPath}/hosts/${machine.hostDir}/machine" ../hosts/${machine.hostDir}/machine; }; };

  # ----- DEFAULT APPS -----
  # V home manageru na to existuje primo `xdg.mimeApps.defaultApplications`, however tam je pak konflikt s uz existujicim konfiguracnim souborem. To resi nasledujici force, pak se to ale musi zapsat manualne pres `xdg.configFile."mimeapps.list".text`
  xdg.configFile."mimeapps.list".force = true; # vyreseno pres https://github.com/nix-community/home-manager/issues/1213
  xdg.configFile."mimeapps.list".text = ''
[Default Applications]
text/html=org.qutebrowser.qutebrowser.desktop
x-scheme-handler/http=org.qutebrowser.qutebrowser.desktop
x-scheme-handler/https=org.qutebrowser.qutebrowser.desktop
x-scheme-handler/about=org.qutebrowser.qutebrowser.desktop
x-scheme-handler/unknown=org.qutebrowser.qutebrowser.desktop
x-scheme-handler/chrome=org.qutebrowser.qutebrowser.desktop
application/x-extension-htm=org.qutebrowser.qutebrowser.desktop
application/x-extension-html=org.qutebrowser.qutebrowser.desktop
application/x-extension-shtml=org.qutebrowser.qutebrowser.desktop
application/xhtml+xml=org.qutebrowser.qutebrowser.desktop
application/x-extension-xhtml=org.qutebrowser.qutebrowser.desktop
application/x-extension-xht=org.qutebrowser.qutebrowser.desktop
image/png=org.qutebrowser.qutebrowser.desktop
image/jpeg=org.qutebrowser.qutebrowser.desktop
image/svg+xml=org.qutebrowser.qutebrowser.desktop

application/pdf=org.pwmt.zathura.desktop
  '';

  # adds desktop entries -> rofi can run them
  xdg.desktopEntries = {
    nixos = {
      name = "Nix Packages";
      genericName = "Website";
      exec = "xdg-open https://search.nixos.org/packages";
      terminal = false;
    };
    home-manager = {
      name = "Home Manager";
      genericName = "Website";
      exec = "xdg-open https://home-manager-options.extranix.com/";
      terminal = false;
    };
  };
}
