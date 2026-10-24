# Hyprland 会话（end4-pC / illogical-impulse）
# 具体 dotfiles 与用户级包在 home/klee/hyprland.nix 里
{ config, lib, ... }:

let
  cfg = config.my.hyprland;
in
{
  options.my.hyprland.enable = lib.mkEnableOption "Hyprland 会话";

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      # end4-pC 的 execs.lua 自己处理 dbus 环境，先直接用 Hyprland 会话
      withUWSM = false;
      xwayland.enable = true;
    };

    # SDDM 默认进入 Hyprland；Plasma 仍保留在会话列表里
    services.displayManager.defaultSession = "hyprland";

    # hyprlock 作为 end4 锁屏失败时的回退
    security.pam.services.hyprlock = { };

    # end4 天气/定位；demo agent 由模块自动装好
    services.geoclue2.enable = true;

    # end4 的剪贴板粘贴用 ydotool 模拟 Ctrl+V
    hardware.uinput.enable = true;
    programs.ydotool = {
      enable = true;
      group = "uinput";
    };
  };
}
