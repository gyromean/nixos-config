
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
  ];
in
{
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
    eog # image viewer
    gdb
    ddcutil # komunikace s monitorem (nastaveni brightness)
    uxplay
    brightnessctl # nastaveni brightness na laptopu
    dunst # potrebuje ho betterlockscreen
    betterlockscreen
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
    adwaita-icon-theme  # default gnome cursors
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
    diff-pdf
    qrcp # servefile alternative
    imagemagick
    fx # json structure explorer
    simplescreenrecorder # screen recorder
    haruna # media player
    rustup
  ];
}
