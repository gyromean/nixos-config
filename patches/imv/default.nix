{ pkgs }:

pkgs.imv.overrideAttrs (old: {
  patches = (old.patches or []) ++ [
    ./mouse-bindings.patch
    ./disable-pinch-rotation.patch
  ];
})
