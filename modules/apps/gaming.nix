# 游戏：Steam 库复用 /mnt/steam，Proton 由 Steam 自行下载
{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    gamescope
    mangohud
    heroic
    lutris
    wine
    winetricks
    protonplus
    hmcl
  ];
}
