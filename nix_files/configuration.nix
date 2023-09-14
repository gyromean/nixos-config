# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  machine = import /etc/nixos/machine_vars.nix;
  # ----- PYTHON PACKAGES -----
  my-python-packages = ps: with ps; [
    sympy
    requests
  ];
in
{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      /etc/nixos/machine_settings.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.i2c.enable = true; # potrebuju pro ovladani brightness monitoru, viz https://www.ddcutil.com/i2c_permissions/ a https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/8

  networking.hostName = machine.hostname; # Define your hostname.
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

  programs.zsh.enable = true; # musi to byt enabled i tady i presto ze to mam primarne v home-manageru, jinak to nemuzu nastavit jako home shell

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # ----- USER PACKAGES ----
  users.users.pavel = {
    isNormalUser = true;
    description = "Pavel Holy";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh; # nastavit zsh jako vychozi shell
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
    xfce.xfce4-terminal
    tree
    cava
    hexedit
    libreoffice
    ripgrep # aby fungoval live_grep ve vim pluginu telescope
    unzip # aby ranger umel unzip
    evince # PDF viewer
    vlc
    gnome.eog # image viewer
    gdb
    ddcutil # komunikace s monitorem (nastaveni brightness)
    uxplay
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
    wmctrl # na ziskani aktualniho workspace, pouzivam to v i3 configuraci
    # nvim lsp servers
    rnix-lsp # nix
    clang-tools
    nodePackages.pyright
    lua-language-server
    nodePackages.bash-language-server
  ];

  # ----- FONTS -----
  # fonty musi byt tady, jinak je aplikace neuvidi
  fonts = {
    # enableDefaultFonts = true;
    fonts = with pkgs; [
      powerline-fonts
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    ];
    fontconfig.defaultFonts.monospace = [
      "Source Code Pro for Powerline"
      "DejaVu Sans" # kvuli braille symbolum, jinak se berou z fontu Freemono a ty se mi nelibi
      "Symbols Nerd Font Mono"
    ];
  };

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
  networking.firewall.enable = false;

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
  
  # ----- AVAHI ----- (pro resolvovalni .local domen)
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  # ----- HOME MANAGER -----
  home-manager.users.pavel = { config, pkgs, ... }: {
    home.stateVersion = "22.05";

    # ----- SETTINGS i3 -----
    xsession.windowManager.i3 = let mod = "Mod4"; in {
      enable = true;
      config = {
        modifier = mod;
        terminal = "xfce4-terminal";
        startup = [
          { command = "xrandr --dpi 96 --output HDMI-0 --off --output DP-0 --mode 2560x1440 --pos 0x0 --rotate normal --rate 165 --output DP-1 --off --output DP-2 --mode 2560x1440 --pos 5120x0 --rotate normal --rate 165 --output DP-3 --off --output DP-4 --mode 2560x1440 --pos 2560x0 --rotate normal --rate 165 --output DP-5 --off"; notification = false; } # nastavi monitory na spravny poradi a spravny refresh rate; `--dpi 96` nastavi scaling UI elementu, ruzny aplikace na to berou ohled (treba chrome)
          { command = "feh --bg-fill ~/.config/nixos-config/wallpaper.png"; notification = false; } # nastaveni wallapper na startupu
          { command = "xset r rate 175 30"; notification = false; } # nastaveni prodlevy pred key repeatem na 175 ms, frekvence key repeatu na 30 Hz
          { command = "numlockx on"; notification = false; } # zapnout numlock pri bootu
          { command = "setxkbmap -layout 'us,cz(qwerty)' -option grp:alt_shift_toggle -option caps:escape_shifted_capslock"; notification = false; } # nastavit qwerty cestinu jako sekundarni klavesnici; nastavit togglovani na alt+shift; caps se chova jak escape, shift+caps se chova jako obycejny caps (kdyz jsem to rozdelil do vicero volani setxkbmap tak to nefungovalo)
          { command = "systemctl --user restart polybar.service"; notification = false; }
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

          "${mod}+u" = ''exec --no-startup-id i3-msg workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | grep '1$')"'';
          "${mod}+i" = ''exec --no-startup-id i3-msg workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | grep '2$')"'';
          "${mod}+o" = ''exec --no-startup-id i3-msg workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | grep '3$')"'';

          "${mod}+Shift+u" = ''exec --no-startup-id i3-msg move container to workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | grep '1$')"'';
          "${mod}+Shift+i" = ''exec --no-startup-id i3-msg move container to workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | grep '2$')"'';
          "${mod}+Shift+o" = ''exec --no-startup-id i3-msg move container to workspace "$(i3-msg -t get_outputs | jq '.[] | .current_workspace' | tr -d '"' | grep '3$')"'';

          "${mod}+1" = ''exec --no-startup-id i3-msg workspace 1:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+2" = ''exec --no-startup-id i3-msg workspace 2:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+3" = ''exec --no-startup-id i3-msg workspace 3:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+4" = ''exec --no-startup-id i3-msg workspace 4:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+5" = ''exec --no-startup-id i3-msg workspace 5:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+6" = ''exec --no-startup-id i3-msg workspace 6:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+7" = ''exec --no-startup-id i3-msg workspace 7:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+8" = ''exec --no-startup-id i3-msg workspace 8:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+9" = ''exec --no-startup-id i3-msg workspace 9:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+0" = ''exec --no-startup-id i3-msg workspace 10:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';

          "${mod}+Shift+1" = ''exec --no-startup-id i3-msg move container to workspace 1:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+2" = ''exec --no-startup-id i3-msg move container to workspace 2:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+3" = ''exec --no-startup-id i3-msg move container to workspace 3:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+4" = ''exec --no-startup-id i3-msg move container to workspace 4:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+5" = ''exec --no-startup-id i3-msg move container to workspace 5:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+6" = ''exec --no-startup-id i3-msg move container to workspace 6:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+7" = ''exec --no-startup-id i3-msg move container to workspace 7:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+8" = ''exec --no-startup-id i3-msg move container to workspace 8:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+9" = ''exec --no-startup-id i3-msg move container to workspace 9:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';
          "${mod}+Shift+0" = ''exec --no-startup-id i3-msg move container to workspace 10:$(wmctrl -d | fgrep '*' | awk '{print $9}' | cut -d':' -f2)'';

          "${mod}+q" = "kill";
          "${mod}+n" = "splitv";
          "${mod}+m" = "splith";
          "${mod}+space" = "floating toggle";
          "${mod}+Shift+space" = "focus mode_toggle";

          # tyhle keybinds se daji zjistit pres program `xev`
          "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioPlay" = "exec --no-startup-id playerctl play-pause";
          "XF86AudioNext" = "exec --no-startup-id playerctl next";
          "XF86AudioPrev" = "exec --no-startup-id playerctl previous";
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
            "${mod}+r" = "mode default";
          };
        };
        window = {
          titlebar = false; # aby nad oknama nebyly jejich nazvy
        };
        gaps = {
          inner = 10;
        };
        bars = []; # vypnout built-in i3 bar (misto nej pouzivam polybar)
        colors = let focused = "#eceff4ff"; unfocused = "#4c566aff"; other = "#ff0000ff"; in { # nastavit obrysy oken (cervenou abych si ji vsiml kdyz se nekdy projevi)
          focused = { # #rrggbbaa
            border = focused; background = other; text = other; # border je to co se ukazuje pri resizovani mysi
            indicator = focused;
            childBorder = focused;
          };
          focusedInactive = {
            border = focused; background = other; text = other;
            indicator = unfocused;
            childBorder = unfocused;
          };
          unfocused = {
            border = focused; background = other; text = other;
            indicator = unfocused;
            childBorder = unfocused;
          };
          placeholder = {
            border = focused; background = other; text = other;
            indicator = other;
            childBorder = other;
          };
          urgent = {
            border = focused; background = other; text = other;
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

workspace 1:1 output DP-0
workspace 1:2 output DP-4
workspace 1:3 output DP-2
'';
    };

    # ----- SETTINGS POLYBAR ------
    services.polybar = {
      enable = true;
      package = pkgs.polybarFull;
      script = ''
PATH=$PATH:/run/current-system/sw/bin
rm /tmp/polybar_*.sock

python ~/.config/nixos-config/polybar_scripts/eyetimer.py &

for m in $(polybar --list-monitors | cut -d":" -f1); do
  MONITOR=$m polybar --reload example &
  python ~/.config/nixos-config/polybar_scripts/brightness.py "$!" "$m" &
done
'';
    };
    xdg.configFile."polybar/config.ini".source = config.lib.file.mkOutOfStoreSymlink "/home/pavel/.config/nixos-config/dotfiles/polybar/config.ini";

    # ----- SETTINGS PICOM -----
    services.picom = {
      enable = true; # bez picomu je za polybarem cerna cast kdyz nema width 100%
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
        vim-airline
        vim-airline-themes
        nord-vim
        nightfox-nvim
        nvim-treesitter.withAllGrammars # viz https://nixos.wiki/wiki/Treesitter
        indent-blankline-nvim # sedy cary na indentation a newline ikona na konci
        undotree
        nvim-treesitter-context
        telescope-nvim
        telescope-fzf-native-nvim
        vim-gitgutter # git stav jednotlivych radek vlevo; pridava do vim-airline countery zmen
        vim-commentary # keybind na toggle comment radku
        vim-surround # keybinds na zmenu uvozovek, zavorek, tagu, ...
        vim-easymotion # rychla navigace v textu
        lsp-zero-nvim
        # dependencies pro lsp-zero-nvim:
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          luasnip
          cmp-path # autocomplete pathu
        lspsaga-nvim-original
      ];
      extraConfig = ''
" ----- COLORSCHEME -----
let g:airline_powerline_fonts = 1
let g:nord_italic = 1
let g:nord_italic_comments = 1 " bacha, oba tyhle italicy musi byt jeste pred zavolanim `colorscheme nord`
colorscheme nord
" nastavit highlight na stejnou barvu jako Search (barvy muzu zobrazit pres `:hi`)
hi! link TelescopeMatching Search
hi! link TelescopePreviewLine Search
hi String ctermfg=14 guifg=#8fbcbb

" ----- SETS -----
set nu rnu
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
set ignorecase " musi byt, aby smartcase fungoval
set smartcase " search je case-insensitive az do momentu, kdy dam neco velkejma
set clipboard=unnamedplus " nastavi clipboard na systemovej clipboard
set gdefault " V substitute se dava defaultne g (replace vsude)
set breakindent " text wrap zacina na stejnym indentation levelu
set splitright " novy okna (treba pres vsplit) se oteviraji vpravo (misto defaultne nahore)
set splitbelow " novy okna se oteviraji dole (misto defaultne nahore)
set tildeop " ted kdyz se da ~ aby se menil case pisma, tak to jeste potrebuje motion (nemeni to individualni charakter)
set scrolloff=8 " pri scrollovani bude nahore a dole vzdycky aspon 8 radek (pokud teda nejsem uplne na zacatku nebo na konci souboru)
set undofile " bude existovat perzistentni historie zmen, ty pak muzu pouzivat jak z vimu tak z undo tree
set noswapfile " nebude se zakladat a pouzivat swap file
set updatetime=100 " mimo jine se bude vim-gitgutter updatovat kazdych 100 ms
set signcolumn=number " signs (z vim-gitgutter nebo lsp) se budou ukazovat ve sloupecku cisel misto tech cisel
set noshowmode " nebude dola ukazovat v jakym jsem modu, protoze to stejne vidim v airline (diky tomu muzu pouzivat `print` z lua v insert modu a bude to vide)

" ----- REBINDS -----
let mapleader = " "
" save a close
nnoremap <C-w> :x<CR>
" save
nnoremap <C-s> :w<CR>
" jednorazove vypne highlight ze search commandu
nnoremap <leader>n :noh<CR>
" paste v insert modu pres ctrl+v; `:h i_CTRL-R_CTRL-O`, ten <C-p> vypne to automaticky vim formatovani ktery to vetsinou posere, viz komentar pod dotazem zde https://vi.stackexchange.com/questions/12049/how-to-set-up-crtl-v-map-that-works-in-insert-mode (v tom komentu je to <C-r><C-p>, ale lepsi je <C-r><C-o> jak pouzivam ja)
inoremap <C-v> <C-r><C-o>+
" na wincmd, takze treba `space+w+s` splitne okno horizontalne, `space+w+v` splitne okno vertikalne atd.
nnoremap <leader>w <C-w>
nnoremap <C-h> :wincmd h<CR>
nnoremap <C-j> :wincmd j<CR>
nnoremap <C-k> :wincmd k<CR>
nnoremap <C-l> :wincmd l<CR>
" v visual modu kdyz neco selectu a prepisu to pres paste, tak se to co prepisuju zkopiruje do clipboardu - tohle zpusobi, ze v clipboardu zustane puvodni obsah
xnoremap <leader>p "_dP
" mazani aniz by se prepsal obsah clipboardu
noremap <leader>d "_d
" otevre Undotree, do nej preskocim jako do jinyho okna, takze <C-h>
nnoremap <leader>u :UndotreeToggle<CR>
nnoremap <C-f> :Telescope find_files<CR>
nnoremap <C-g> :Telescope live_grep<CR>
" easymotion prebindovat na [ a ]
nnoremap [[ <Plug>(easymotion-F)
nnoremap ]] <Plug>(easymotion-f)
xnoremap [[ <Plug>(easymotion-F)
xnoremap ]] <Plug>(easymotion-f)
" easymotion prebindovat na [ a ] i v pythonu, protoze u nej se to samo prebinduje
autocmd FileType python nnoremap <buffer> [[ <Plug>(easymotion-F)
autocmd FileType python nnoremap <buffer> ]] <Plug>(easymotion-f)
autocmd FileType python xnoremap <buffer> [[ <Plug>(easymotion-F)
autocmd FileType python xnoremap <buffer> ]] <Plug>(easymotion-f)
" navigace uvnitr snippetu z autocompletu
inoremap <C-h> <cmd>lua require'luasnip'.jump(-1)<CR>
snoremap <C-h> <cmd>lua require'luasnip'.jump(-1)<CR>
inoremap <C-l> <cmd>lua require'luasnip'.jump(1)<CR>
snoremap <C-l> <cmd>lua require'luasnip'.jump(1)<CR>
inoremap <C-y> <cmd>lua require'luasnip'.jump(1)<CR>
snoremap <C-y> <cmd>lua require'luasnip'.jump(1)<CR>
" vlozeni slozenych zavorek
inoremap <C-p> <end><CR>{<CR>}<up><end><CR>
" search results jsou vzdy uprostred obrazovky (ted to funguje jen smerem dopredu, <C-N> je for some reason MALE n)
nnoremap <C-N> nzz

" ----- PLUGINS SETTINGS -----
" ----- COMMENTARY -----
autocmd FileType nix setlocal commentstring=#\ %s

" ----- EASYMOTION -----
let g:EasyMotion_smartcase = 1 " nastavit smart case hledani
      '';
      extraLuaConfig = ''
-- ----- TREESITTER ----
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
  },
}

-- ----- LSP ZERO -----
local lsp = require('lsp-zero').preset({
  name = 'recommended',
  set_lsp_keymaps = false
})

lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr}

  vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
  vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
  vim.keymap.set('n', 'go', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
  vim.keymap.set('n', 'gl', '<cmd>Lspsaga lsp_finder<cr>', opts)
  vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
  vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
  vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<cr>', opts)
  vim.keymap.set('n', 'gx', '<cmd>Lspsaga code_action<cr>', opts)
  vim.keymap.set('n', 'gr', '<cmd>Lspsaga rename<cr>', opts)
  vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
  vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)
  vim.keymap.set('i', '<C-x>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
end)

lsp.setup_servers({'rnix', 'clangd', 'pyright', 'lua_ls', 'bashls'})

lsp.setup()

lsp.set_sign_icons({ -- musi se volat az po lsp.setup()
  error = '◆',
  warn = '▲',
  hint = '■',
})

-- ----- CMP ----- (musi byt az po setupu LSP ZERO)
local cmp = require('cmp')
local cmp_select_opts = {behavior = cmp.SelectBehavior.Select}
cmp.setup({
  mapping = {
    ['<CR>'] = cmp.config.disable,
    ['<C-P>'] = cmp.config.disable, -- for some reason to musi byt velky P
    ['<C-d>'] = cmp.mapping(function(fallback) fallback() end, {"s"}), -- disablovat <C-d> v select modu, idk jestli je to dobre
    ['<Tab>'] = cmp.mapping(function(fallback) fallback() end, {"s", "i"}), -- disablovat <C-d> v select modu, idk jestli je to dobre

    ['<C-j>'] = cmp.mapping.select_next_item(),
    ['<C-k>'] = cmp.mapping.select_prev_item(),
  }
})

-- ----- LSPSAGA -----
require('lspsaga').setup({
  lightbulb = {
    enable = false
  },
  symbol_in_winbar = {
    enable = false
  },
  beacon = {
    enable = false
  },
  rename = {
    quit = 'q'
  },
  ui = {
    code_action = "🅱️ ased"
  },
})

-- ----- INDENT BLANKLINE -----
vim.opt.list = true
vim.opt.listchars:append "eol:↴"

require("indent_blankline").setup {
  show_end_of_line = true,
}

-- ----- TREESITTER CONTEXT ----
require'treesitter-context'.setup{
  enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
  max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
  min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
  line_numbers = true,
  multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
  trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
  -- Separator between context and content. Should be a single character string, like '-'.
  -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
  separator = nil,
  zindex = 20, -- The Z-index of the context window
  on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
}

-- ----- TELESCOPE -----
require'telescope'.setup{
  defaults = {
    mappings = {
      i = {
        ["<C-j>"] = 'move_selection_next',
        ["<C-k>"] = 'move_selection_previous',
        ["<C-s>"] = 'select_horizontal'
      }
    },
    path_display = { "truncate" } -- aby se ukazovala prava cast pathu pri hledani
  },
  pickers = {
    find_files = {
      hidden = true, -- ukazovat hidden files
      find_command = { "find", "-type", "f,l" } -- pridat prepinac `-type l`, jinak to neukazovalo linky, a tech je v NixOS hodne
    },
    live_grep = {
      additional_args = { "--hidden", "--follow" } -- ukazovat hidden files a followovat linky
    }
  }
}
require'telescope'.load_extension('fzf') -- kvuli extensionu, musi se to volat az po volani require'telescope'.setup, https://github.com/nvim-telescope/telescope-fzf-native.nvim

-- ----- CUSTOM SETTINSG -----
vim.diagnostic.config({ virtual_text = true }) -- ukaze inline diagnostics (musi se volat az po setupu lsp-zero)
'';
    };

    xdg.configFile."nvim/after/plugin/init_after.vim".text = ''
sunmap <leader><leader>
'';

    # -- NEOVIM AFTER FILETYPE PLUGINS --
    xdg.configFile."nvim/after/ftplugin/python.vim".text = ''
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
nnoremap <buffer><leader>d :s/\v^( *)(.*)$/\1print(f'{\2 = }')<CR>:noh<CR>
xnoremap <buffer><leader>d :s/\v^( *)(.*)$/\1print(f'{\2 = }')<CR>:noh<CR>
'';

    xdg.configFile."nvim/after/ftplugin/c.vim".text = ''
set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
nnoremap <buffer><leader>d :call CDebugPrint()<CR>
xnoremap <buffer><leader>d :call CDebugPrint()<CR>

function! CDebugPrint() range
  let selector = input('Selector: ')
  let pattern = '\v^( *)(.*)$'
  let sub = '\1printf("\2 = %' .. selector .. '\\n", (\2));'
  if selector == '''
    return
  elseif selector == 'p'
    let sub = '\1printf("\2 = %' .. selector .. '\\n", ((void*)\2));'
  endif
  exec printf('silent!%d,%ds/%s/%s/', a:firstline, a:lastline, pattern, sub)
endfunction
'';

    xdg.configFile."nvim/after/ftplugin/cpp.vim".text = ''
set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
nnoremap <buffer><leader>d :s/\v^( *)(.*)$/\1cerr << "\2 = " << (\2) << endl;<CR>:noh<CR>
xnoremap <buffer><leader>d :s/\v^( *)(.*)$/\1cerr << "\2 = " << (\2) << endl;<CR>:noh<CR>
'';

    xdg.configFile."nvim/after/ftplugin/json.vim".text = ''
set equalprg=jq " pouzit na formatovani program jq
'';

    xdg.configFile."nvim/after/ftplugin/lua.vim".text = ''
set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
'';

    xdg.configFile."nvim/after/ftplugin/dosini.vim".text = ''
set formatoptions-=cro " vypnuti komentaru na dalsich radkach kdyz dam enter
'';

    xdg.configFile."nvim/after/ftplugin/markdown.vim".text = ''
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab
'';
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
    family: monospace
    style: Regular
  bold:
    family: monospace
    style: Bold
  italic:
    family: monospace
    style: Italic
  bold_italic:
    family: monospace
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
      enableAutosuggestions = false;
      enableSyntaxHighlighting = true;
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
      };
      # ty '' pred $ to escapujou v nixu, do relanyho .zshrc se nepropisou
      initExtra = ''
# sourcenout git prompts pro igloo (nord) theme
. ${pkgs.git.outPath}/share/git/contrib/completion/git-prompt.sh

# sourcenout igloo theme https://github.com/arcticicestudio/igloo/tree/master/snowblocks/zsh
fpath=(~/.config/nixos-config/zsh_themes $fpath)

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
source ~/.config/nixos-config/custom_scripts/scripts_to_source.sh
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
