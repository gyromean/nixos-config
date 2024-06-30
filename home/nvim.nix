{ config, pkgs, lib, machine, ... }:

{
  xsession.windowManager.i3 = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      terminal = "alacritty";
      startup = [
        { command = machine.monitorSetup; notification = false; } # nastavi monitory na spravny poradi a spravny refresh rate; `--dpi 96` nastavi scaling UI elementu, ruzny aplikace na to berou ohled (treba chrome)
        { command = "feh --bg-fill ${../wallpaper.png}"; notification = false; } # nastaveni wallapper na startupu
        { command = "xset r rate 175 30"; notification = false; } # nastaveni prodlevy pred key repeatem na 175 ms, frekvence key repeatu na 30 Hz
        { command = "numlockx on"; notification = false; } # zapnout numlock pri bootu
        { command = "setxkbmap -layout 'us,cz(qwerty)' -option grp:alt_shift_toggle -option caps:escape_shifted_capslock"; notification = false; } # nastavit qwerty cestinu jako sekundarni klavesnici; nastavit togglovani na alt+shift; caps se chova jak escape, shift+caps se chova jako obycejny caps (kdyz jsem to rozdelil do vicero volani setxkbmap tak to nefungovalo)
        { command = "systemctl --user restart polybar.service"; notification = false; }
        { command = "rm /tmp/i3-workspace-groups-*"; notification = false; }
      ];
      keybindings = lib.mkOptionDefault {
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";

        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";

        "${modifier}+u" = ''exec --no-startup-id i3-msg workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | fgrep ':1:')"'';
        "${modifier}+i" = ''exec --no-startup-id i3-msg workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | fgrep ':2:')"'';
        "${modifier}+o" = ''exec --no-startup-id i3-msg workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | fgrep ':3:')"'';

        "${modifier}+Shift+u" = ''exec --no-startup-id i3-msg move container to workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | fgrep ':1:')"'';
        "${modifier}+Shift+i" = ''exec --no-startup-id i3-msg move container to workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | fgrep ':2:')"'';
        "${modifier}+Shift+o" = ''exec --no-startup-id i3-msg move container to workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | fgrep ':3:')"'';

        "${modifier}+1" = ''exec --no-startup-id i3-msg workspace 1:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+2" = ''exec --no-startup-id i3-msg workspace 2:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+3" = ''exec --no-startup-id i3-msg workspace 3:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+4" = ''exec --no-startup-id i3-msg workspace 4:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+5" = ''exec --no-startup-id i3-msg workspace 5:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+6" = ''exec --no-startup-id i3-msg workspace 6:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+7" = ''exec --no-startup-id i3-msg workspace 7:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+8" = ''exec --no-startup-id i3-msg workspace 8:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+9" = ''exec --no-startup-id i3-msg workspace 9:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+0" = ''exec --no-startup-id i3-msg workspace 10:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';

        "${modifier}+Shift+1" = ''exec --no-startup-id i3-msg move container to workspace 1:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+2" = ''exec --no-startup-id i3-msg move container to workspace 2:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+3" = ''exec --no-startup-id i3-msg move container to workspace 3:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+4" = ''exec --no-startup-id i3-msg move container to workspace 4:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+5" = ''exec --no-startup-id i3-msg move container to workspace 5:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+6" = ''exec --no-startup-id i3-msg move container to workspace 6:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+7" = ''exec --no-startup-id i3-msg move container to workspace 7:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+8" = ''exec --no-startup-id i3-msg move container to workspace 8:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+9" = ''exec --no-startup-id i3-msg move container to workspace 9:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
        "${modifier}+Shift+0" = ''exec --no-startup-id i3-msg move container to workspace 10:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';

        "${modifier}+p" = ''exec python /home/pavel/.config/custom/scripts/i3-workspace-groups.py select-group'';
        "${modifier}+Shift+p" = ''exec python /home/pavel/.config/custom/scripts/i3-workspace-groups.py'';
        "${modifier}+s" = "exec --no-startup-id flameshot gui";

        "${modifier}+q" = "kill";
        "${modifier}+n" = "splitv";
        "${modifier}+m" = "splith";
        "${modifier}+w" = "layout toggle stacked tabbed";
        "${modifier}+z" = "focus mode_toggle";
        "${modifier}+Shift+z" = "floating toggle";

        "${modifier}+x" = ''mode "exit: [s]hutdown, [r]estart, [l]ock, sl[e]ep, l[o]gout"'';

        # tyhle keybinds se daji zjistit pres program `xev`
        "XF86AudioRaiseVolume" = "exec --no-startup-id echo up | /run/current-system/sw/bin/nc -w0 -U /tmp/polybar_audio.sock";
        "XF86AudioLowerVolume" = "exec --no-startup-id echo down | /run/current-system/sw/bin/nc -w0 -U /tmp/polybar_audio.sock";
        "XF86AudioMute" = "exec --no-startup-id echo left | /run/current-system/sw/bin/nc -w0 -U /tmp/polybar_audio.sock";
        "XF86AudioPlay" = "exec --no-startup-id playerctl play-pause";
        "XF86AudioNext" = "exec --no-startup-id playerctl next";
        "XF86AudioPrev" = "exec --no-startup-id playerctl previous";
        "XF86MonBrightnessUp" = "exec --no-startup-id echo increase | /run/current-system/sw/bin/nc -U /tmp/polybar_brightness.sock";
        "XF86MonBrightnessDown" = "exec --no-startup-id echo decrease | /run/current-system/sw/bin/nc -U /tmp/polybar_brightness.sock";
      };
      modes = {
        "resize" = {
          "h" = "resize shrink width 3 px or 3 ppt";
          "j" = "resize shrink height 3 px or 3 ppt";
          "l" = "resize grow width 3 px or 3 ppt";
          "k" = "resize grow height 3 px or 3 ppt";

          "Left" = "resize shrink width 3 px or 3 ppt";
          "Down" = "resize shrink height 3 px or 3 ppt";
          "Right" = "resize grow width 3 px or 3 ppt";
          "Up" = "resize grow height 3 px or 3 ppt";

          "Return" = "mode default";
          "Escape" = "mode default";
          "${modifier}+r" = "mode default";
        };
        "exit: [s]hutdown, [r]estart, [l]ock, sl[e]ep, l[o]gout" = {
          "s" = ''exec "systemctl poweroff"'';
          "r" = ''exec "systemctl reboot"'';
          "l" = ''exec "i3-msg mode default; betterlockscreen -l"'';
          "e" = ''exec "i3-msg mode default; systemctl suspend; betterlockscreen -l"'';
          "o" = ''exec "i3-msg exit"'';

          "Return" = "mode default";
          "Escape" = "mode default";
          "${modifier}+x" = "mode default";
        };
      };
      window = {
        titlebar = false; # aby nad oknama nebyly jejich nazvy
      };
      gaps = {
        inner = 10;
      };
      bars = []; # vypnout built-in i3 bar (misto nej pouzivam polybar)
      colors = let focused = "#eceff4ff"; unfocused = "#4c566aff"; other = "#ff0000ff"; title_bright = "#88C0D0ff"; title_dark = "#2E3440ff"; in { # nastavit obrysy oken (cervenou abych si ji vsiml kdyz se nekdy projevi)
        focused = { # #rrggbbaa
          border = focused; # border je to co se ukazuje pri resizovani mysi
          background = title_bright;
          text = title_dark;
          indicator = focused;
          childBorder = focused;
        };
        focusedInactive = {
          border = unfocused;
          background = title_dark;
          text = title_bright;
          indicator = unfocused;
          childBorder = unfocused;
        };
        unfocused = {
          border = unfocused;
          background = title_dark;
          text = title_bright;
          indicator = unfocused;
          childBorder = unfocused;
        };
        placeholder = {
          border = other;
          background = title_dark;
          text = title_bright;
          indicator = other;
          childBorder = other;
        };
        urgent = {
          border = other;
          background = title_dark;
          text = title_bright;
          indicator = other;
          childBorder = other;
        };
      };
      focus.wrapping = "no";
    };
    extraConfig = ''
# zapnout jeden terminal v scratchpadu pri bootu
for_window [title="__scratchpad"] move scratchpad
exec --no-startup-id xfce4-terminal --title __scratchpad

${machine.workspaceSetup}
'';
  };

  # ----- SETTINGS VIRTMANAGER ------
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # ----- SETTINGS VSCODE ------
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

  # ----- SETTINGS POLYBAR ------
  services.polybar = {
    enable = true;
    package = pkgs.polybarFull;
    script = ''
PATH=$PATH:/run/current-system/sw/bin
rm /tmp/polybar_*.sock

for m in $(polybar --list-monitors | cut -d":" -f1); do
MONITOR=$m polybar --reload example &
polybar_pid="$!"
${machine.polybarBrightness}
${machine.polybarI3Workspaces}
done

python ~/.config/custom/polybar-scripts/eyetimer.py &
python ~/.config/custom/polybar-scripts/audio.py &

python ~/.config/custom/scripts/i3-workspace-groups.py refresh-polybar
'';
  };

  # ----- SETTINGS PICOM -----
  services.picom = {
    enable = true; # bez picomu je za polybarem cerna cast kdyz nema width 100%
    vSync = true; # opravit screen tearing, viz https://unix.stackexchange.com/questions/421622/how-to-get-rid-of-background-flickering-when-switching-workspaces
    backend = "glx";
    fade = true;
    fadeDelta = 1;
    fadeSteps = [ 1 1 ];
  };

  # ----- SETTINGS FZF ------
  programs.fzf = {
    enable = true;
    defaultCommand = "find ."; # jinak to neukazuje hidden files
    colors = {
      "fg" = "#d0d0d0";
      "bg" = "-1";
      "hl" = "#88c0d0";
      "fg+" = "#d0d0d0";
      "bg+" = "-1";
      "hl+" = "#88c0d0";
      "info" = "#616e88";
      "prompt" = "#d0d0d0";
      "pointer" = "#d0d0d0";
      "marker" = "#d0d0d0";
      "spinner" = "#d0d0d0";
      "header" = "#d0d0d0";
    };
  };

  # ----- SETTINGS GIT ------
  programs.git = {
    enable = true;
    aliases = {
      st = "status";
      ci = "commit";
      co = "checkout";
      br = "branch";
      ll = "log --oneline --graph --all --decorate";
      last = "log --oneline --graph --decorate HEAD^..HEAD";
      d = "diff";
      dc = "diff --cached";
      cim = "commit -m";
      ap = "add -p";
      au = "add -u";
    };
    extraConfig = {
      user = {
        email = "gyro1125@gmail.com";
        name = "Pavel Holy";
      };
      diff = {
        algorithm = "patience";
      };
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "nord";
      vim_keys = true;
      update_ms = 500;
    };
  };

  # ----- SETTINGS FLAMESHOT -----
  services.flameshot = { # screenshoty
    enable = true;
  };

  # ----- SETTINGS FOOT -----
  programs.foot = { # terminal
    enable = true;
    settings = { # https://codeberg.org/dnkl/foot/src/branch/master/themes/nord
      main = {
        font = "Droid Sans Mono Dotted for Powerline:size=8";
      };
      cursor = {
        color = "2e3440 d8dee9";
      };
      
      colors = {
        foreground = "d8dee9";
        background = "2e3440";
      
        regular0 = "3b4252";
        regular1 = "bf616a";
        regular2 = "a3be8c";
        regular3 = "ebcb8b";
        regular4 = "81a1c1";
        regular5 = "b48ead";
        regular6 = "88c0d0";
        regular7 = "e5e9f0";
      
        bright0 = "4c566a";
        bright1 = "bf616a";
        bright2 = "a3be8c";
        bright3 = "ebcb8b";
        bright4 = "81a1c1";
        bright5 = "b48ead";
        bright6 = "8fbcbb";
        bright7 = "eceff4";
      
        dim0 = "373e4d";
        dim1 = "94545d";
        dim2 = "809575";
        dim3 = "b29e75";
        dim4 = "68809a";
        dim5 = "8c738c";
        dim6 = "6d96a5";
        dim7 = "aeb3bb";
      };
    };
  };

  # ----- SETTIGNS NEOVIM -----
  # `nix-env -f '<nixpkgs>' -qaP -A vimPlugins` - pro vypsani podporovanejch pluginu (jakoze asi vim vs neovim ale idk)
  programs.neovim = {
    enable = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      lualine-nvim
      nord-nvim
      nightfox-nvim
      nvim-treesitter.withAllGrammars # viz https://nixos.wiki/wiki/Treesitter
      undotree
      nvim-treesitter-context
      telescope-nvim
      telescope-fzf-native-nvim
      vim-gitgutter # git stav jednotlivych radek vlevo; pridava do vim-airline countery zmen
      vim-commentary # keybind na toggle comment radku
      vim-surround # keybinds na zmenu uvozovek, zavorek, tagu, ...
      vim-easymotion # rychla navigace v textu
      nvim-ts-autotag
      lsp-zero-nvim
      # dependencies pro lsp-zero-nvim:
        nvim-lspconfig
        nvim-cmp
        cmp-nvim-lsp
        luasnip
        cmp_luasnip
        cmp-path # autocomplete pathu
      lspsaga-nvim
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-dap-python
      todo-comments-nvim
      vimtex
      harpoon2
      oil-nvim
    ];
  };

  # ----- SETTIGNS ALACRITTY -----
  programs.alacritty = {
    enable = true;
  };

  # ----- SETTINGS TMUX -----
  programs.tmux = {
    enable = true;
  };

  # ----- SETTINGS ZSH -----
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
  }; # TODO - nastavit to jako default shell

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

  xdg.configFile."xfce4/terminal/terminalrc".text = ''
[Configuration]
FontName=Monospace 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=120x35
MiscInheritGeometry=FALSE
MiscMenubarDefault=FALSE
MiscMouseAutohide=FALSE
MiscMouseWheelZoom=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=TRUE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscMiddleClickOpensUri=FALSE
MiscCopyOnSelect=FALSE
MiscShowRelaunchDialog=TRUE
MiscRewrapOnResize=TRUE
MiscUseShiftArrowsToScroll=FALSE
MiscSlimTabs=FALSE
MiscNewTabAdjacent=FALSE
ShortcutsNoMnemonics=TRUE
ShortcutsNoMenukey=TRUE
ShortcutsNoHelpkey=TRUE
MiscSearchDialogOpacity=100
MiscShowUnsafePasteDialog=FALSE
MiscRightClickAction=TERMINAL_RIGHT_CLICK_ACTION_CONTEXT_MENU
ColorCursor=#D8DEE9
ColorForeground=#D8DEE9
ColorBackground=#2E3440
TabActivityColor=#88C0D0
ColorPalette=#3B4252;#BF616A;#A3BE8C;#EBCB8B;#81A1C1;#B48EAD;#88C0D0;#E5E9F0;#4C566A;#BF616A;#A3BE8C;#EBCB8B;#81A1C1;#B48EAD;#8FBCBB;#ECEFF4
ColorBold=#D8DEE9
ColorBoldUseDefault=FALSE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ScrollingUnlimited=TRUE
'';

  xdg.configFile."ranger/rc.conf".text = ''
set show_hidden true
'';
}
