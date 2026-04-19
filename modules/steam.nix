{ config, pkgs, ... }:

{
  # Steam 相关程序配置
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    # ... 其他原有配置保持不变
    extraPackages = with pkgs; [
      zenity
      xdg-utils
      SDL2
      libglvnd
      vulkan-loader
      vulkan-validation-layers
      libpulseaudio
    ];
    # extest.enable = true;
  };
   programs.gamemode.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };
}
