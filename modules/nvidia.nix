{ config, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    # 移动版 2070 建议开启电源管理以支持挂起/恢复
    powerManagement.enable = true;
    powerManagement.finegrained = false; # 单显卡环境下不需要 finegrained

    open = true; # TU106M (20系) 建议使用闭源驱动以获得最佳稳定性
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # 显存管理器支持
    #powerManagement.enableOffloadCmd = false;
  };

  # NVIDIA 环境变量 (在 Hyprland 下必不可少)
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1"; # 避免 NVIDIA 下光标不可见
  };
}
