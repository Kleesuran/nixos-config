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
    protonup-qt
    steam-run
  ];
}
