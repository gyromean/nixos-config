{ config, pkgs, lib, machine, opts, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      asvetliakov.vscode-neovim
      arcticicestudio.nord-visual-studio-code
      ms-python.python
      ms-toolsai.jupyter
      ms-toolsai.jupyter-renderers
    ];
    userSettings = {
      "workbench.colorTheme" = "Nord";
      "jupyter.widgetScriptSources" = ["jsdelivr.com" "unpkg.com"];
      "git.openRepositoryInParentFolders" = "never";
      "keyboard.dispatch" = "keyCode";
    };
  };
}
