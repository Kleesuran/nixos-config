{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.profiles.daed;
  lockedDaedPackage = inputs.daeuniverse.packages.${pkgs.system}.daed;
  daedPackage =
    if cfg.packagePreset == "custom" then
      cfg.customPackage
    else
      lockedDaedPackage;

  seedDaedCache = pkgs.writeShellApplication {
    name = "seed-daed-cache";
    runtimeInputs = with pkgs; [ coreutils nix ];
    text = ''
      set -euo pipefail

      cache_dir="''${1:-/run/media/klee/KIOXIA/Audiobooks/nixos/.nix-cache}"
      package_path="$(nix build --no-link --print-out-paths /run/media/klee/KIOXIA/Audiobooks/nixos#nixosConfigurations.klee.config.services.daed.package)"

      mkdir -p "$cache_dir"
      nix copy --to "file://$cache_dir" "$package_path"

      echo "Seeded daed closure into $cache_dir"
      echo "Package path: $package_path"
    '';
  };

  restoreDaedCache = pkgs.writeShellApplication {
    name = "restore-daed-cache";
    runtimeInputs = with pkgs; [ coreutils gnutar ];
    text = ''
      set -euo pipefail

      if [ "$#" -ne 1 ]; then
        echo "usage: restore-daed-cache <daed-cache.tar.gz>" >&2
        exit 1
      fi

      archive="$(realpath "$1")"
      cache_dir="/run/media/klee/KIOXIA/Audiobooks/nixos/.nix-cache"

      mkdir -p "$cache_dir"
      tar -C "$cache_dir" -xzf "$archive"

      echo "Restored daed cache into $cache_dir"
    '';
  };

{
  options.profiles.daed = {
    packagePreset = lib.mkOption {
      type = lib.types.enum [ "locked" "custom" ];
      default = "locked";
      description = ''
        Which daed package source to use. `locked` uses the daeuniverse flake
        revision pinned in flake.lock. `custom` lets you inject a known-good
        fallback package from an overlay or local derivation.
      '';
    };

    customPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Optional fallback daed package used when packagePreset = \"custom\".";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.packagePreset != "custom" || cfg.customPackage != null;
        message = "profiles.daed.customPackage must be set when profiles.daed.packagePreset = \"custom\".";
      }
    ];

  services.daed = {
    enable = true;
    # 默认使用 flake.lock 锁定的 daeuniverse 包；如需回退到旧版，
    # 可通过 profiles.daed.packagePreset/customPackage 注入已知可用包。
    package = daedPackage;
  };

  environment.systemPackages = [
    restoreDaedCache
    seedDaedCache
  ];

  networking.firewall.allowedTCPPorts = [ 2023 ];
  };
}
