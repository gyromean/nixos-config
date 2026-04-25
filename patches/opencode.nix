{ pkgs, inputs }:
let
  opencodePkgs = import inputs.opencode.inputs.nixpkgs {
    inherit (pkgs.stdenv.hostPlatform) system;
    overlays = [ inputs.opencode.overlays.default ];
  };

  patchedOpencodeNodeModules = (opencodePkgs.callPackage "${inputs.opencode.outPath}/nix/node_modules.nix" {
    rev = "da6683f";
    hash = "sha256-7ewQQael53XA5Jb69AeQrep5UYKERYF1N5mTSYMSAjI=";
  }).overrideAttrs (_old: {
    # Temporary upstream packaging fix: include the root workspace so root devDependencies
    # like prettier are available during the opencode build.
    buildPhase = ''
      runHook preBuild
      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install \
        --cpu="${if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x64"}" \
        --os="${if pkgs.stdenv.hostPlatform.isLinux then "linux" else "darwin"}" \
        --filter './' \
        --filter './packages/opencode' \
        --filter './packages/desktop' \
        --filter './packages/app' \
        --filter './packages/shared' \
        --frozen-lockfile \
        --ignore-scripts \
        --no-progress
      bun --bun ${inputs.opencode.outPath}/nix/scripts/canonicalize-node-modules.ts
      bun --bun ${inputs.opencode.outPath}/nix/scripts/normalize-bun-binaries.ts
      runHook postBuild
    '';
  });
in
opencodePkgs.opencode.override {
  node_modules = patchedOpencodeNodeModules;
}
