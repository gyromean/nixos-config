{
  description = "gyromean's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        (host:
        let
          machine = import ./hosts/${host}/vars.nix;
        in {
          name = machine.hostname;
          value = lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit machine opts; };
            modules = [
              ./hosts/${host}
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users."${opts.username}" = import ./home;
                home-manager.extraSpecialArgs = { inherit machine opts; };
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
