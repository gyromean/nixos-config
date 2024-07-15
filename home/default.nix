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
        (dir: type: type == "directory")
        (builtins.readDir ./.)
      )
    ) // { ".config/machine" = { source = linkFunc "${opts.configPath}/hosts/${machine.hostDir}/machine" ../hosts/${machine.hostDir}/machine; }; };

  # ----- DEFAULT APPS -----
  # V home manageru na to existuje primo `xdg.mimeApps.defaultApplications`, however tam je pak konflikt s uz existujicim konfiguracnim souborem. To resi nasledujici force, pak se to ale musi zapsat manualne pres `xdg.configFile."mimeapps.list".text`
  xdg.configFile."mimeapps.list".force = true; # vyreseno pres https://github.com/nix-community/home-manager/issues/1213
  xdg.configFile."mimeapps.list".text = ''
[Default Applications]
text/html=google-chrome.desktop
x-scheme-handler/http=google-chrome.desktop
x-scheme-handler/https=google-chrome.desktop
x-scheme-handler/about=google-chrome.desktop
x-scheme-handler/unknown=google-chrome.desktop
x-scheme-handler/chrome=google-chrome.desktop
application/x-extension-htm=google-chrome.desktop
application/x-extension-html=google-chrome.desktop
application/x-extension-shtml=google-chrome.desktop
application/xhtml+xml=google-chrome.desktop
application/x-extension-xhtml=google-chrome.desktop
application/x-extension-xht=google-chrome.desktop

[Added Associations]
x-scheme-handler/http=firefox.desktop;
x-scheme-handler/https=firefox.desktop;
x-scheme-handler/chrome=firefox.desktop;
text/html=firefox.desktop;
application/x-extension-htm=firefox.desktop;
application/x-extension-html=firefox.desktop;
application/x-extension-shtml=firefox.desktop;
application/xhtml+xml=firefox.desktop;
application/x-extension-xhtml=firefox.desktop;
application/x-extension-xht=firefox.desktop;
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
