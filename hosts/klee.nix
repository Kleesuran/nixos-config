{ config, pkgs, ... }:

{
  imports = [
    ./klee-hardware.nix
    ../modules/boot.nix
    ../modules/system.nix
    ../modules/graphics.nix
    ../modules/cuda.nix
    ../modules/plasma.nix
    ../modules/hyprland.nix
    ../modules/input.nix
    ../modules/game.nix
    ../modules/daed.nix
    ../modules/devops-lab.nix
    ../modules/klee-storage.nix
    ../modules/hardware.nix
  ];

  # 启用图形支持并指定 GPU 类型 (nvidia/amd/intel)
  drivers.graphics = {
    enable = true;
    gpuType = "nvidia";
  };

  # 启用 CUDA 与容器 GPU 加速
  drivers.cuda.enable = true;

  # 启用当前设备 (2070m) 特定的硬盘挂载策略
  device.klee-2070m.enable = true;

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
    
    # 自定义本地 MiSans 字体打包
    (stdenv.mkDerivation {
      pname = "misans";
      version = "1.0";
      src = ../config/fonts/misans;
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp MiSansVF.ttf $out/share/fonts/truetype/
      '';
    })
  ];

  environment.systemPackages = with pkgs; [
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
  system.stateVersion = "25.11";
}
