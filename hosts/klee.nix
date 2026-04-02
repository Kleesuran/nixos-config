{ config, pkgs, ... }:

{
  imports = [
    ./klee-hardware.nix
    ../modules/boot.nix
    ../modules/system.nix
    ../modules/nvidia.nix
    ../modules/plasma.nix
    ../modules/hyprland.nix
    ../modules/input.nix
    ../modules/game.nix
    ../modules/firewall.nix
    ../modules/clash.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

  networking.hostName = "klee";
  time.timeZone = "Asia/Shanghai";

  users.users.klee = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "networkmanager" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # 音频支持
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # 字体设置
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    flclash
    clash-verge-rev
    mihomo  # 推荐安装作为后端支持
  ];

  # ==================== 修复 FlClash 文件导出与桌面适配问题 ====================
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common.default = "*";
  };

  # system.stateVersion 必须放在这里面！
  system.stateVersion = "24.11";
}
