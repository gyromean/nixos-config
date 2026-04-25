{ pkgs, inputs }:
let
  opencodePkgs = import inputs.opencode.inputs.nixpkgs {
    inherit (pkgs.stdenv.hostPlatform) system;
    overlays = [ inputs.opencode.overlays.default ];
  };

  patchedOpencodeNodeModules = import ./opencode-packaging.nix { inherit pkgs inputs; };
in
opencodePkgs.opencode.overrideAttrs (old: {
  node_modules = patchedOpencodeNodeModules;
  configurePhase = import ./opencode-opentui-resume.nix { inherit old; };
})
