{ config, pkgs, lib, machine, opts, ... }:
{
  programs.zsh = { # shell
    enable = true;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = true;
    history.share = false;
    oh-my-zsh = {
      enable = true;
      plugins = [ "copypath" "copyfile" ];
    };
    shellAliases = {
      v = "vim";
      r = "ranger";
      x = "xdg-open &>/dev/null";
      n = "(nemo . &>/dev/null &)";
      airplay = "uxplay -nh -n PC -s 1920x1080@120 -fps 120";
      nv = "neovide";
      g = "git";
    };
    # ty '' pred $ to escapujou v nixu, do relanyho .zshrc se nepropisou
    initExtra = ''
# sourcenout git prompts pro igloo (nord) theme
. ${pkgs.git.outPath}/share/git/contrib/completion/git-prompt.sh

# sourcenout igloo theme https://github.com/arcticicestudio/igloo/tree/master/snowblocks/zsh
fpath=(~/.config/custom/zsh-themes $fpath)

# nahrat prompts https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#Prompt-Themes, nastavit options pro ZSH
autoload -U promptinit
promptinit
IGLOO_ZSH_PROMPT_THEME_ALWAYS_SHOW_HOST=true
IGLOO_ZSH_PROMPT_THEME_ALWAYS_SHOW_USER=true
IGLOO_ZSH_PROMPT_THEME_HIDE_TIME=true
prompt igloo

# fixnout lag pri pastovani
# This speeds up pasting w/ autosuggest
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
OLD_SELF_INSERT=''${''${(s.:.)widgets[self-insert]}[2,3]}
zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# nainstalovat zsh-vi-mode, viz https://github.com/jeffreytse/zsh-vi-mode#nix
source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# prompt bude vzdycky na zacatku v insert modu
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

# znovu zprovoznit fzfovou zsh integraci, protoze ten vim mode ji castecne overwritnul
zvm_after_init_commands+=('[ -f ${pkgs.fzf}/share/fzf/completion.zsh ] && source ${pkgs.fzf}/share/fzf/completion.zsh')
zvm_after_init_commands+=('[ -f ${pkgs.fzf}/share/fzf/key-bindings.zsh ] && source ${pkgs.fzf}/share/fzf/key-bindings.zsh')

# custom skripty
source ~/.config/custom/zsh-scripts/scripts-to-source.sh
'';
  };
}
