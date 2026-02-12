{
  description = "gyromean's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pala.url = "github:gyromean/pala"; # must NOT follow nixpkgs, use its own locked nixpkgs
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-ags-1.url = "github:nixos/nixpkgs/d0fc30899600b9b3466ddb260fd83deb486c32f1";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    opts = rec {
      # --- change these options ---
      username = "pavel";
      enableSymlinks = true;
      # ----------------------------

      homeDirectory = "/home/${username}";
      configPath = "${homeDirectory}/.config/nixos-config";
    };
    lib = nixpkgs.lib;
    mkNixosConfigs = hostsDirectories:
    (builtins.listToAttrs
      (builtins.map
        (hostDir:
        let
          machine = import ./hosts/${hostDir}/vars.nix;
        in {
          name = machine.hostname;
          value = lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = inputs // { inherit opts; machine = machine // { inherit hostDir; }; };
            modules = [
              ./hosts/${hostDir}
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users."${opts.username}" = import ./home;
                home-manager.extraSpecialArgs = inputs // { inherit opts; machine = machine // { inherit hostDir; }; };
              }
            ];
          };
        })
        hostsDirectories
      )
    );
  in {
    nixosConfigurations = mkNixosConfigs [ "desktop" "laptop" ];
  };
}
