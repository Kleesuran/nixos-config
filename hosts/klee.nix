{ config, pkgs, ... }:

{
  imports = [
    ./klee-hardware.nix
    ../modules/boot.nix
    ../modules/bootloader-grub.nix
    ../modules/system.nix
    ../modules/graphics.nix
    ../modules/cuda.nix
    ../modules/plasma.nix
    ../modules/hyprland.nix
    ../modules/input.nix
    ../modules/game.nix
    ../modules/steam.nix
    ../modules/daed.nix
    ../modules/devops-lab.nix
    ../modules/hardware.nix
    ../modules/themes.nix
    ../modules/options.nix
  ];

  # ==================== Klee 系统控制面板 ====================
  klee = {
    gpu = {
      type = "nvidia";  # 自动触发 drivers.graphics 和 drivers.cuda
      cuda = true;
    };
    boot = {
      mode = "standalone"; # NixOS 独立引导，接管 BIOS 启动项
      efiSysMountPoint = "/boot";
    };
    daed = {
      enable = true;
      useFallback = false; # 如果网络死锁，临时改为 true，并确保 .nix-cache/daed-bin 存在
    };
  };
  # ==========================================================

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
