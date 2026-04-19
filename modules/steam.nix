{ config, pkgs, ... }:

{
  # Steam 相关程序配置
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraPackages = with pkgs; [
      zenity
      xdg-utils
      SDL2
      libglvnd
      libGL
      vulkan-loader
      vulkan-validation-layers
      libpulseaudio
      libx11
      libxcursor
      libxi
      libxinerama
      libxrandr
      libxrender
      libxscrnsaver
      libxxf86vm
    ];
  };
  programs.gamemode.enable = true;
}
