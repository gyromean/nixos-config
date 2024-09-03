{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/configuration.nix
    ./hardware-configuration.nix
  ];

  # get options generated by wihotspot from the linux-wifi-hotspot package
  services.create_ap = {
    enable = true;
    settings = {
      CHANNEL = "default";
      GATEWAY = "192.168.69.1";
      WPA_VERSION = "2";
      DHCP_DNS = "gateway";
      HIDDEN = 0;
      MAC_FILTER = 1;
      MAC_FILTER_ACCEPT = builtins.toFile "mac_filter" "50:ED:3C:CB:40:F2"; # iPad's mac
      SHARE_METHOD = "nat";
      NO_VIRT = 0;
      FREQ_BAND = "2.4";
      WIFI_IFACE = "wlp1s0";
      INTERNET_IFACE = "wlp1s0";
      SSID = "xHZOaiDDZPBv";
      PASSPHRASE = "iMn3RZEJLexI";
    };
  };
}
