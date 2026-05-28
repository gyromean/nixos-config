# Repo Notes

- Trust `flake.nix` over `README.md`. The README still describes old channel-based setup and broken symlink paths; the active repo entrypoint is the flake.
- Flake outputs are keyed by hostname, not directory name: `pavelpc`, `pavellt`, `pavelltvm`. The matching source directories are `hosts/desktop`, `hosts/laptop`, `hosts/laptopvm`.
- Cheap verification: `nix flake show --all-systems` or `nix eval --json .#nixosConfigurations --apply builtins.attrNames`.
- Full host verification/apply uses the hostname output, e.g. `sudo nixos-rebuild test --flake .#pavelpc` or `sudo nixos-rebuild switch --flake .#pavelpc`.

# Structure

- `flake.nix` builds every host by importing `./hosts/<dir>/vars.nix`; adding a new host requires adding its directory name to `mkNixosConfigs`.
- `legacy-hosts/` is archival and is not included in flake outputs; do not treat those hosts as active unless explicitly asked.
- Shared NixOS settings live in `modules/configuration.nix`; host-only overrides live in `hosts/<dir>/default.nix` plus `hardware-configuration.nix`.
- Host feature flags come from `hosts/<dir>/vars.nix` (`wireguardEnabled`, `syncthingEnabled`, monitor/workspace settings, hostname). Do not hardcode those elsewhere.
- `home/default.nix` auto-imports every `home/*.nix` except `default.nix`. Adding a new top-level `.nix` file there automatically enables it.
- `home/default.nix` also symlinks every directory under `home/` except `nolink` into `~/.config/<dir>`, and symlinks `hosts/<hostDir>/machine` to `~/.config/machine`.
- `opts.enableSymlinks = true` means many Home Manager files intentionally use out-of-store symlinks back into this repo; avoid "fixing" that to store paths unless explicitly asked.

# Verified Gotchas

- The repo assumes username `pavel` and repo path `/home/pavel/.config/nixos-config` via `opts` in `flake.nix`; some modules still hardcode `pavel` or `/home/pavel` directly.
- Default MIME apps are managed manually in `home/default.nix` via forced `mimeapps.list`, not `xdg.mimeApps.defaultApplications`, to avoid a Home Manager conflict.
- Current forced defaults send image MIME types, including `image/png`, `image/jpeg`, and `image/svg+xml`, to `imv.desktop`, not `feh` or qutebrowser.
- No repo-local CI, formatter, or pre-commit config was found. Do not invent a required lint/test pipeline; use flake eval/rebuild commands instead.
