{ pkgs, ... }:

let
  steamPackage = pkgs.steam.override {
    extraPkgs = steamPkgs: with steamPkgs; [
      keyutils
      libkrb5
      libpng
      libpulseaudio
      libvorbis
      stdenv.cc.cc.lib
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
      xorg.libXScrnSaver
    ];
  };

  steamFixNtfsLibrary = pkgs.writeShellApplication {
    name = "steam-fix-ntfs-library";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      set -euo pipefail

      if [ "$#" -ne 1 ]; then
        echo "usage: steam-fix-ntfs-library <steam-library-root>" >&2
        echo "example: steam-fix-ntfs-library /run/media/klee/DATA-M.2/SteamLibrary" >&2
        exit 1
      fi

      library_root="$(realpath "$1")"
      steamapps_dir="$library_root/steamapps"

      if [ ! -d "$steamapps_dir" ]; then
        echo "steamapps directory not found under: $library_root" >&2
        exit 1
      fi

      safe_name="$(
        printf '%s' "$library_root" \
          | tr '/:' '__'
      )"
      target_dir="$HOME/.local/share/steam-compatdata/$safe_name"
      compatdata_link="$steamapps_dir/compatdata"

      mkdir -p "$target_dir"

      if [ -L "$compatdata_link" ]; then
        current_target="$(realpath "$compatdata_link")"
        if [ "$current_target" = "$target_dir" ]; then
          echo "compatdata already points to $target_dir"
          exit 0
        fi

        echo "compatdata already points elsewhere: $current_target" >&2
        exit 1
      fi

      if [ -e "$compatdata_link" ]; then
        echo "existing $compatdata_link detected; move or remove it before creating the symlink" >&2
        exit 1
      fi

      ln -s "$target_dir" "$compatdata_link"
      echo "created symlink: $compatdata_link -> $target_dir"
    '';
  };
in
{
  programs.steam = {
    enable = true;
    package = steamPackage;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    protontricks
    protonup-qt
    steam-run
    steamFixNtfsLibrary
    vulkan-tools
  ];
}
