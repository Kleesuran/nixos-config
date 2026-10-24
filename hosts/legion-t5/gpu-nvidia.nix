# NVIDIA RTX 2070 Mobile / Max-Q（TU106M，独显无核显）
{ config, lib, pkgs, ... }:

let
  # 595.104.02 的 nvidia-smi 被 patchelf 打出重叠的 PT_LOAD，.dynamic
  # 落在只读段，ld.so 写 DT_DEBUG 时段错误。这里只替换 nvidia-smi 这一个
  # 可执行文件，内核模块和其余用户态组件保持原样；上游布局修复后脚本会自动跳过。
  nvidiaSmiFixed = pkgs.runCommand "nvidia-smi-elf-fix" { } ''
    mkdir -p $out/bin
    cp ${config.hardware.nvidia.package.bin}/bin/nvidia-smi $out/bin/nvidia-smi
    chmod u+w $out/bin/nvidia-smi
    ${pkgs.python3}/bin/python3 ${../../pkgs/fix-elf-load-flags.py} $out/bin/nvidia-smi
    chmod 0555 $out/bin/nvidia-smi
  '';
in
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam 的 32 位游戏
    # VA-API 解码（OpenUUYC 主控端用 H.264 硬解）
    extraPackages = [ pkgs.nvidia-vaapi-driver ];
  };

  hardware.nvidia = {
    modesetting.enable = true;

    # 单显卡机器，无需 PRIME 细粒度电源管理
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Arch 上用的是 nvidia-open-dkms，Turing 支持开源内核模块
    open = true;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot = {
    kernelParams = [ "nvidia-drm.modeset=1" ];
    initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
    blacklistedKernelModules = [ "nouveau" ];

    # 休眠/挂起后保持显存
    extraModprobeConfig = ''
      options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
    '';
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = [
    pkgs.nvtopPackages.nvidia
    # vainfo：KDE「系统信息 / 关于本机」的图形页要用，也是 VA-API 排障工具。
    # 放在 systemPackages 而不是 graphics.extraPackages —— 后者只建
    # /run/opengl-driver 的驱动目录，不往 PATH 里放可执行文件。
    pkgs.libva-utils
    # 覆盖驱动自带的 nvidia-smi（同路径冲突时优先使用本包）
    (lib.hiPrio nvidiaSmiFixed)
  ];
}
