{ pkgs, inputs }:

let
  opencodePkgs = import inputs.opencode.inputs.nixpkgs {
    inherit (pkgs.stdenv.hostPlatform) system;
    overlays = [ inputs.opencode.overlays.default ];
  };
in
opencodePkgs.opencode.overrideAttrs (old: {
  configurePhase = old.configurePhase + ''
    # Upstream requires bun 1.3.14, but their flake still pins nixpkgs with
    # bun 1.3.13. Using 1.3.14 currently produces broken compiled binaries on
    # NixOS, so keep upstream's pinned bun and relax only the build-time guard.
    substituteInPlace packages/script/src/index.ts \
      --replace-fail \
      'const expectedBunVersionRange = `^''${expectedBunVersion}`' \
      'const expectedBunVersionRange = ">=1.3.13 <1.4.0"'
  '';
})
