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
      username = "pavel";

      homeDirectory = "/home/${username}";
      configPath = "${homeDirectory}/.config/nixos-config";
    };
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      pavelpc = let
        machine = import ./hosts/desktop/vars.nix;
      in lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit machine opts; };
        modules = [
          ./hosts/desktop
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.pavel = import ./home;
            home-manager.extraSpecialArgs = { inherit machine opts; };
          }
        ];
      };
    };
  };
}
