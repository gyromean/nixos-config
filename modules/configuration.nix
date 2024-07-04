# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, machine, opts, ... }:
let
  # ----- PYTHON PACKAGES -----
  my-python-packages = ps: with ps; [
    sympy
    requests
    dbus-python # potrebuje ho instalator certifikatu na FIT eduroam
    beautifulsoup4
    blessed
    i3ipc
    numpy
    pandas
    matplotlib
    ipykernel
    ipympl
    pycryptodome
    pyqt6
    manim-slides
  ];
in
{
  imports =
    [ # Include the results of the hardware scan.
    ];

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    useOSProber = true;
    efiSupport = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  hardware.i2c.enable = true; # potrebuju pro ovladani brightness monitoru, viz https://www.ddcutil.com/i2c_permissions/ a https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/8

  networking.hostName = machine.hostname; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  networking.interfaces.virtbr = {
    useDHCP = true;
  };
  networking.bridges = {
    "virtbr" = {
      interfaces = [ machine.defaultInterface ];
      # interfaces = [];
    };
  };

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
    xkb.layout = "us";
    xkb.variant = "";
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

  services.syncthing = let
    devices =
      (builtins.listToAttrs
        (builtins.map
          (path: let
            vars = import path;
            in { name = vars.hostname; value = { id = vars.syncthingId; }; }
          )
          (builtins.filter
            (path: builtins.pathExists path)
            (lib.attrsets.mapAttrsToList
              (path: type: ../hosts/${path}/vars.nix)
              (lib.attrsets.filterAttrs
                (name: type: type == "directory")
                (builtins.readDir ../hosts)
              )
            )
          )
        )
      );

    shareFolder = (path: {
      path = path;
      versioning.type = "trashcan";
      devices = lib.attrsets.mapAttrsToList (name: value: name) (builtins.removeAttrs devices [ machine.hostname ]);
    });
  in {
    enable = true;
    user = "pavel";
    dataDir = "/home/pavel/sync";
    configDir = "/home/pavel/.config/syncthing";
    overrideDevices = true;     # overrides any devices added or deleted through the WebUI
    overrideFolders = true;     # overrides any folders added or deleted through the WebUI
    settings = {
      devices = builtins.removeAttrs devices [ machine.hostname ];
      folders = {
        "Sync" = shareFolder "/home/pavel/sync";
        "School" = shareFolder "/home/pavel/skola";
      };
    };
  };

  # enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  programs.dconf.enable = true; # virt-manager requires dconf to remember settings

  services.upower.enable = true; # vypsat moznosti pres `upower -e`, potom stav treba pres `upower -i /org/freedesktop/UPower/devices/battery_BAT0`

  programs.zsh.enable = true; # musi to byt enabled i tady i presto ze to mam primarne v home-manageru, jinak to nemuzu nastavit jako home shell

  programs.steam.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # ----- USER PACKAGES ----
  users.users.pavel = {
    isNormalUser = true;
    description = "Pavel Holy";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "docker" ];
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
    brightnessctl # nastaveni brightness na laptopu
    dunst # potrebuje ho betterlockscreen
    betterlockscreen
    rofi
    fd # alternativa prikazu find
    libimobiledevice # pro kopirovani souboru z iPhone
    ifuse # pro kopirovani souboru z iPhone
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
    nixd # nix language server
    clang-tools
    pyright
    lua-language-server
    nodePackages.bash-language-server
    ntfs3g
    inotify-tools # pro inotifywait
    gnumake
    neovide
    openssl
    ncdu
    nmap
    virt-manager
    gdbgui
    file
    kotlin
    evtest # ziskani prichozich eventu z klavesnice/mysi
    manim # program pro tvorbu animaci z pythoniho zdrojaku
    qmk # firmware pro custom klavesnice
    graphviz
    dos2unix # prevedeni CRLF na LF
    bvi # binary vi, alternativa hexeditu
    man-pages # man pages treba pro Ceckovy veci
    man-pages-posix # idk taky nejaky man pages
    moreutils # dalsi veci, treba `errno -l` vypise, co ktery errno znamena
    (hiPrio parallel) # viz https://discourse.nixos.org/t/why-is-parallel-overwritten-by-moreutils-s-parallel/36979/2
    pavucontrol # audio
    qpwgraph # audio
    ffmpeg
    dust # neco jako windirstat
    tldr # tldr man pages
    texliveFull
    zathura # lightweight pdf viewer s vim keybinds
    xdotool # simuluje keyboard input a mouse activity (je potreba kvuli interakci zathura a vimtex pluginu)
    texlab # LSP for LaTeX
    httpie # alternative to curl
    wezterm # terminal emulator
    ltex-ls # grammar and spell checker language server
    lua
    slides # terminal based presentation tool
    graph-easy # drawing ascii art graphs (nodes and edges)
    gef # frontend for gdb
    screenkey # display pressed keys in gui overlay
    pdfgrep # grep in pdf files
    poppler_utils # contains pdfseparate for splitting pdf to multiple pdfs
    fast-downward # pddl planning system
    python312Packages.servefile # simple http server for serving file to download or providing file upload functionality
    python311Packages.debugpy # python debugger
    manim-slides
    diff-pdf
    qrcp # servefile alternative
    imagemagick
    fx # json structure explorer
    simplescreenrecorder # screen recorder
  ];

  # ----- FONTS -----
  # fonty musi byt tady, jinak je aplikace neuvidi
  fonts = {
    # enableDefaultFonts = true;
    packages = with pkgs; [
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
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.keyboard.qmk.enable = true;

  programs.light.enable = true; # aby ve Swayi sel menit brightess a volume https://nixos.wiki/wiki/Sway

  # konfigurace asi jde i takhle:
  #xdg.configFile."sway/config".text = '''';

  services.usbmuxd.enable = true; # pro kopirovani souboru z iPhone

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
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      clickMethod = "clickfinger";
    };
  };
  
  # ----- AVAHI ----- (pro resolvovalni .local domen)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  # ----- SETTINGS ENVIRONMENT ----- #
  environment.variables = {
    EDITOR = "nvim"; # nvim default editor; aby tohle zafungovalo, tak se musim relognout (nestaci `sudo nixos-rebuild switch`)
    PATH = [
      "/home/pavel/programy/path_links"
    ];
  };



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
