{ pkgs, ... }:

{
  # 引导加载器
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
