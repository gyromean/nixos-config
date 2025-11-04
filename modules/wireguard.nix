{ config, pkgs, lib, machine, opts, ... }@inputs:
{
  networking.wireguard.interfaces = let
    server_ip = "213.220.196.186";
  in {
    wg0 = { # home
      ips = [ "10.7.7.202/32" ];
      listenPort = 51820;
      privateKeyFile = "/home/pavel/.wg/private";
      peers = [
        {
          publicKey = "H+vCG4c3QWCewQGNgHGY8SVw6COXa9gyAkEWMag2rgE=";
          allowedIPs = [ "10.7.7.0/24" ];
          endpoint = "${server_ip}:11945";
          persistentKeepalive = 25;
        }
      ];
    };
    wg1 = { # ALT raspberry
      ips = [ "10.15.15.100/32" ];
      listenPort = 51821;
      privateKeyFile = "/home/pavel/.wg/private";
      peers = [
        {
          publicKey = "MW6Fpcn1wl3YU/58dJ8jTF5rA+vuTjiC3U+3+eGO/QU=";
          allowedIPs = [ "10.15.15.0/24" ];
          endpoint = "${server_ip}:11946";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
