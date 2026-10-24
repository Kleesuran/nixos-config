# 游戏：Steam 库路径由 Steam 自己记录（本机是 /mnt/steam），Proton 由 Steam 自行下载
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
