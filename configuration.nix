# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  # ----- PYTHON PACKAGES -----
  my-python-packages = ps: with ps; [
    sympy
    requests
  ];
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "bruhpc"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT = "cs_CZ.UTF-8";
    LC_MONETARY = "cs_CZ.UTF-8";
    LC_NAME = "cs_CZ.UTF-8";
    LC_NUMERIC = "cs_CZ.UTF-8";
    LC_PAPER = "cs_CZ.UTF-8";
    LC_TELEPHONE = "cs_CZ.UTF-8";
    LC_TIME = "cs_CZ.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  #services.xserver.desktopManager.gnome.enable = true; # TODO - tady jsem to zakomentaroval

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # ----- USER PACKAGES ----
  users.users.pavel = {
    isNormalUser = true;
    description = "Pavel Holy";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # web browsers:
      firefox
      google-chrome # https://unix.stackexchange.com/questions/429765/howto-install-google-chrome-in-nixos, `nix-env -qa | grep google-chrome`
      # terminal emulators:
      kitty
      # other:
      discord
      neofetch
      htop
      mc
      gnat # g++
      jq
      # screenshot programs:
      slurp # necha selectnout obdelnik na obrazovce
      # file managers:
      mate.caja # taky jako nemo
      xfce.thunar # OK, lehce uglier nemo
      nnn # zajimavy, cli
      ranger # hezky, cli
      broot # zajimavy, CLI, ma to fuzzy searching nebo jak se to jmenuje
      cinnamon.nemo-with-extensions # OK, klasika
      gnome.nautilus # asi moc simple, klasika
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # ----- GLOBAL PACKAGES -----
  environment.systemPackages = with pkgs; [
    (python3.withPackages my-python-packages) # nainstaluje python packages, jejich seznam se definuje nekde nahore
    nix
    neovim
    vim
    feh # lighweight image viewer, hlavne se da pouzit pro nastaveni wallaperu
    xorg.xdpyinfo
    xclip
    numlockx
    tree
    # waybar:
    # --- SWAY PACKAGES ---
    pulseaudioFull # abych mohl nastavovat hlasitost pres pactl (pouzivam to v konfiguraci swaye)
    playerctl # aby fungovaly tlacitka na hudbu (next, prev, play/pause)
    #configure-gtk # TODO - vratit
    xdg-utils # for opening default programs when clicking links
    glib # gsettings
    dracula-theme # gtk theme
    gnome3.adwaita-icon-theme  # default gnome cursors
    grim # screenshot functionality
    slurp # screenshot functionality
    #(xdg-desktop-portal-gnome.overrideAttrs (oldAttrs: rec { version = "43.1"; }))
  ];

  # ----- FONTS -----
  # fonty musi byt tady, jinak je aplikace neuvidi
  fonts.fonts = with pkgs; [
    powerline-fonts
    font-awesome # pro waybar, aby mel ikonky
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # ----- AUTOMOUNTERS -----
  services.devmon.enable = true; # bez tehle nefunguje ze se mi v nemu zobrazi fleska nebo jiny partitions (sice na ty jiny partitions nema nemo privilegia, ale aspon neco xd)
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  security.polkit.enable = true; # neco pro Sway, https://nixos.wiki/wiki/Sway
  hardware.opengl = {
    enable = true;
    driSupport = true; # NVIDIA
    driSupport32Bit = true;
  };

  # ----- NVIDIA { -----
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
    ];

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  # ----- NVIDIA } -----


  programs.light.enable = true; # aby ve Swayi sel menit brightess a volume https://nixos.wiki/wiki/Sway

  # konfigurace asi jde i takhle:
  #xdg.configFile."sway/config".text = '''';

  # ----- i3 ----- # https://nixos.wiki/wiki/I3#Enabling
  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw 
  services.xserver = {
    #enable = true; # protoze uz je to enabled nekde nahore

    desktopManager = {
      xterm.enable = false;
    };
   
    #displayManager = {
    #    defaultSession = "none+i3";
    #};

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu #application launcher most people use
        i3status # gives you the default i3 status bar
        i3lock #default i3 screen locker
        i3blocks #if you are planning on using i3blocks over i3status
     ];
    };
  };
  

  # ----- HOME MANAGER -----
  home-manager.users.pavel = {
    home.stateVersion = "22.05";

    # ----- SETTINGS i3 -----
    xsession.windowManager.i3 = let mod = "Mod4"; in {
      enable = true;
      config = {
        modifier = mod;
        terminal = "alacritty";
        startup = [
          { command = "xrandr --dpi 96 --output HDMI-0 --off --output DP-0 --mode 2560x1440 --pos 5120x0 --rotate normal --rate 165 --output DP-1 --off --output DP-2 --mode 2560x1440 --pos 2560x0 --rotate normal --rate 165 --output DP-3 --off --output DP-4 --mode 2560x1440 --pos 0x0 --rotate normal --rate 165 --output DP-5 --off"; notification = false; } # nastavi monitory na spravny poradi a spravny refresh rate; `--dpi 96` nastavi scaling UI elementu, ruzny aplikace na to berou ohled (treba chrome)
          { command = "feh --bg-fill ~/.config/wallpaper.png"; notification = false; } # nastaveni wallapper na startupu
          { command = "xset r rate 175 30"; notification = false; } # nastaveni prodlevy pred key repeatem na 175 ms, frekvence key repeatu na 30 Hz
          { command = "numlockx on"; notification = false; } # zapnout numlock pri bootu
        ];
        keybindings = lib.mkOptionDefault {
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";

          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";

          "${mod}+q" = "kill";
          "${mod}+n" = "splitv";
          "${mod}+m" = "splith";
        };
        window = {
          titlebar = false; # aby nad oknama nebyly jejich nazvy
        };
        gaps = {
          inner = 10;
        };
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
      };
    };

    # ----- SETTINGS SWAY -----
    /*
    wayland.windowManager.sway = {
      enable = true;
      config = rec {
        modifier = "Mod4"; # windows button jako modifier
        terminal = "foot"; # terminal foot
        input = { # pridani cestiny, https://wiki.archlinux.org/title/sway#Keymap, `man sway-input`, `man xkeyboard-config`
          "*" = {
            xkb_layout = "us,cz(qwerty)";
            xkb_options = "grp:win_space_toggle";
          };
        };
        bars = [
          { command = "${pkgs.waybar}/bin/waybar"; } # pouzit waybar
        ];
        startup = [
          { command = "swaymsg 'exec ${terminal} --title Scratchpad; for_window [title=\"Scratchpad\"] move scratchpad'"; } # zapnout terminal ve scratchpadu na pozadi pri startu swaye
        ];
        keybindings = lib.mkOptionDefault { # dalsi keybindings a keybindings pro cestinu
          "${modifier}+q" = "kill";
          "${modifier}+n" = "splitv";
          "${modifier}+m" = "splith";

          # Cestina:
          "${modifier}+plus" = "workspace number 1"; # ty jmena pres program `xev` nebo `wev`
          "${modifier}+ecaron" = "workspace number 2";
          "${modifier}+scaron" = "workspace number 3";
          "${modifier}+ccaron" = "workspace number 4";
          "${modifier}+rcaron" = "workspace number 5";
          "${modifier}+zcaron" = "workspace number 6";
          "${modifier}+yacute" = "workspace number 7";
          "${modifier}+aacute" = "workspace number 8";
          "${modifier}+iacute" = "workspace number 9";

          "${modifier}+Shift+plus" = "move container to workspace number 1";
          "${modifier}+Shift+ecaron" = "move container to workspace number 2";
          "${modifier}+Shift+scaron" = "move container to workspace number 3";
          "${modifier}+Shift+ccaron" = "move container to workspace number 4";
          "${modifier}+Shift+rcaron" = "move container to workspace number 5";
          "${modifier}+Shift+zcaron" = "move container to workspace number 6";
          "${modifier}+Shift+yacute" = "move container to workspace number 7";
          "${modifier}+Shift+aacute" = "move container to workspace number 8";
          "${modifier}+Shift+iacute" = "move container to workspace number 9";

          "${modifier}+equal" = "scratchpad show";
          "${modifier}+Shift+equal" = "move scratchpad";

          "${modifier}+space" = "nop"; # defaultne je to nabindovany na `focus mode_toggle`, coz se pere se switchovanim jazyka klavesnice; takhle pres nop se disablne default behaviour
        };
        modes = {
          resize = let step = "30"; in { # timhle nastavim velikost pri resizovani okna
            Down = "resize shrink height ${step} px";
            Left = "resize shrink width ${step} px";
            Right = "resize grow width ${step} px";
            Up = "resize grow height ${step} px";
            h = "resize shrink width ${step} px";
            j = "resize shrink height ${step} px";
            k = "resize grow height ${step} px";
            l = "resize grow width ${step} px";

            Escape = "mode default";
            Return = "mode default";
            q = "mode default";
          };
        };
      };
      extraConfig = ''
# Brightness
bindsym XF86MonBrightnessDown exec light -U 10
bindsym XF86MonBrightnessUp exec light -A 10

# Zvuk/media
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

# Delay a frekvence key-repeatu https://wiki.archlinux.org/title/sway
# Misto <identifier> se tam musi dosadit konkretni klavesnice
# Identifier se zjisti z `swaymsg -t get_inputs` (`man sway-input`)
input 1:1:AT_Translated_Set_2_keyboard repeat_delay 175
input 1:1:AT_Translated_Set_2_keyboard repeat_rate 30
input 1:1:AT_Translated_Set_2_keyboard xkb_numlock enabled # zapnutej numlock po prihlaseni do systemu

# Nastaveni touchpadu
input 1267:12608:ELAN0001:00_04F3:3140_Touchpad tap enabled
input 1267:12608:ELAN0001:00_04F3:3140_Touchpad natural_scroll enabled
input 1267:12608:ELAN0001:00_04F3:3140_Touchpad scroll_factor .2

output * bg ~/.config/wallpaper.png fill
gaps inner 10
      '';
    };
    */

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
        vim-airline
        vim-airline-themes
        nord-vim
        nightfox-nvim
      ];
      extraConfig = ''
set nu rnu
let g:airline_powerline_fonts = 1
let g:nord_italic = 1
let g:nord_italic_comments = 1 "bacha, oba tyhle italicy musi byt jeste pred zavolanim `colorscheme nord`
colorscheme nord
set clipboard=unnamedplus
nnoremap <C-w> :x<CR>
nnoremap <C-s> :w<CR>
let mapleader = " "
nnoremap <leader>n :noh<CR>
set gdefault
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set ignorecase
set smartcase
inoremap <C-v> <C-r>+
      '';
    };

    # ----- SETTIGNS ALACRITTY -----
    programs.alacritty = {
      enable = true;
    };
    # manualne nastavit konfigurak, protoze pres home-manager to replacuje newlines doslovnymi '\n' (reverse engineernuto z https://github.com/nix-community/home-manager/blob/master/modules/programs/alacritty.nix)
    # colorscheme z https://github.com/nordtheme/alacritty/blob/main/src/nord.yaml
    # nastaveni fontu z https://wiki.archlinux.org/title/Alacritty#Font
    xdg.configFile."alacritty/alacritty.yml".text = ''
colors:
  primary:
    background: "#2e3440"
    foreground: "#d8dee9"
    dim_foreground: "#a5abb6"
  cursor:
    text: "#2e3440"
    cursor: "#d8dee9"
  vi_mode_cursor:
    text: "#2e3440"
    cursor: "#d8dee9"
  selection:
    text: CellForeground
    background: "#4c566a"
  search:
    matches:
      foreground: CellBackground
      background: "#88c0d0"
    footer_bar:
      background: "#434c5e"
      foreground: "#d8dee9"
  normal:
    black: "#3b4252"
    red: "#bf616a"
    green: "#a3be8c"
    yellow: "#ebcb8b"
    blue: "#81a1c1"
    magenta: "#b48ead"
    cyan: "#88c0d0"
    white: "#e5e9f0"
  bright:
    black: "#4c566a"
    red: "#bf616a"
    green: "#a3be8c"
    yellow: "#ebcb8b"
    blue: "#81a1c1"
    magenta: "#b48ead"
    cyan: "#8fbcbb"
    white: "#eceff4"
  dim:
    black: "#373e4d"
    red: "#94545d"
    green: "#809575"
    yellow: "#b29e75"
    blue: "#68809a"
    magenta: "#8c738c"
    cyan: "#6d96a5"
    white: "#aeb3bb"

font:
  normal:
    family: Source Code Pro for Powerline
    style: Regular
  bold:
    family: Source Code Pro for Powerline
    style: Bold
  italic:
    family: Source Code Pro for Powerline
    style: Italic
  bold_italic:
    family: Source Code Pro for Powerline
    style: Bold Italic
  size: 11
      '';

    # ----- SETTINGS TMUX -----
    programs.tmux = {
      enable = true;
    };

    # ----- SETTINGS ZSH -----
    programs.zsh = { # shell
      enable = true;
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "sudo" ];
        #theme = "robbyrussell";
        #theme = "agnoster";
        #theme = "bira";
        #theme = "crunch";
        #theme = "dallas";
        #theme = "darkblood";
        #theme = "dstufft";
        #theme = "fino-time";
        #theme = "funky";
        #theme = "gozilla"; # zajimavy, ale nevypisuje se tam full path
        #theme = "half-life";
        #theme = "jaischeema"; # zajimava sipecka
        #theme = "jonathan"; # return code posledniho commandu
        #theme = "simonoff";
        #theme = "smt";
        #theme = "terminalparty";
        #theme = "trapd00r"; # xd strasici message COMMIT
        theme = "igloo"; # xd strasici message COMMIT
      };
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
  };

  # ----- SETTINGS ENVIRONMENT ----- #
  environment.variables.EDITOR = "nvim"; # nvim default editor; aby tohle zafungovalo, tak se musim relognout (nestaci `sudo nixos-rebuild switch`)



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
