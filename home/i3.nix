{ config, pkgs, lib, machine, opts, ... }:
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
      keybindings = lib.mkOptionDefault ({
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
      }
      //
      (lib.foldl
        (acc: set: acc // set) {}
        (builtins.map
          (num:
          let
            mod = a: b: a - (a / b) * b;
            a = builtins.toString (mod num 10);
            b = builtins.toString num;
          in
          {
            "${modifier}+${a}" = ''exec --no-startup-id i3-msg workspace ${b}:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
            "${modifier}+Shift+${a}" = ''exec --no-startup-id i3-msg move container to workspace ${b}:$(wmctrl -d | fgrep '*' | awk '{print $9}' | sed -e 's/^[^:]*://g')'';
          })
          (lib.range 1 10)
        )
      ));

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
}
