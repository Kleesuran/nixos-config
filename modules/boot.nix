{ pkgs, ... }:

{
  # 引导加载器：切换为 GRUB 以获得更好的多系统支持和高分辨率
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot"; # 确保这与你的 hardware-configuration.nix 一致
    };
    grub = {
      enable = true;
      device = "nodev"; # 对于 EFI 系统，设置为 nodev
      efiSupport = true;
      useOSProber = true; # 自动扫描 Windows 等其他操作系统
      
      # 设置 GRUB 界面分辨率
      # "auto" 通常能工作，但如果你的屏幕分辨率很高（如 2K/4K），
      # 显式指定（如 "2560x1440" 或 "1920x1080"）效果更好
      gfxmodeEfi = "auto"; 
      
      # 将旧的 NixOS 版本收纳进子菜单，保持主界面整洁
      # 默认 NixOS 会创建一个 "NixOS - All configurations" 的子菜单
      configurationLimit = 10; # 限制保存的版本数量，防止菜单过长
    };
  };

  # Plymouth 动画主题
  boot.plymouth = {
    enable = true;
    theme = "simple";
    themePackages = [
      (pkgs.stdenv.mkDerivation {
        pname = "plymouth-theme-simple";
        version = "1.0";
        src = ../config/programs/plymouth/simple;
        installPhase = ''
          mkdir -p $out/share/plymouth/themes/simple
          cp -r * $out/share/plymouth/themes/simple/
          substituteInPlace $out/share/plymouth/themes/simple/simple.plymouth \
            --replace "@out@" "$out"
        '';
      })      
    ];
  };

  # 网络拥塞控制 (BBR)
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    "net.core.wmem_max" = 1073741824;
    "net.core.rmem_max" = 1073741824;
    "net.ipv4.tcp_rmem" = "4096 87380 1073741824";
    "net.ipv4.tcp_wmem" = "4096 87380 1073741824";
  };

  # 内核优化参数 (AMD & Logging)
  boot.kernelParams = [
    "quiet" "splash" "boot.shell_on_fail"
    "loglevel=3" "rd.systemd.show_status=false" "rd.udev.log_level=3"
    "amd_pstate=active" "tsc=reliable"
  ];

  # CPU 性能模式
  powerManagement.cpuFreqGovernor = "performance";
}
