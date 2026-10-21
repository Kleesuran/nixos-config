# NVIDIA RTX 2070 Mobile / Max-Q（TU106M，独显无核显）
{ config, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam 的 32 位游戏
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
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
}
