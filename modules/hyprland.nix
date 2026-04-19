{ pkgs, ... }:

{
  # 启用 Hyprland
  programs.hyprland.enable = true;

  # ilyamiro 风格核心工具
  environment.systemPackages = with pkgs; [
    # 基础 UI 工具
    matugen
    quickshell
    swaynotificationcenter
    rofi
    waybar
    
    # 截图与多媒体
    grim
    slurp
    satty
    playerctl
    swayosd
    
    # 辅助工具
    wget
    killall
    fzf
    yq-go
    p7zip
    fastfetch
    
    # 文件管理器与终端辅助
    gnome-tweaks
    nautilus
    xdg-desktop-portal-gtk
  ];

  # XDG Portal 适配 (已统一到 hosts/klee.nix 或此处集中管理)
  # 建议在 Hyprland 模块中完整定义，方便桌面环境解耦
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common.default = "*";
  };
}
