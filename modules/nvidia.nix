{ config, pkgs, ... }:

{
  # 启用 NVIDIA 驱动
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # 启用额外的硬件加速包
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  hardware.nvidia = {
    # 模式设置，Hyprland (Wayland) 必需
    modesetting.enable = true;

    # 对于 RTX 2070 (Turing 架构)，闭源驱动在性能和 CUDA 稳定性上依然由于开源版本
    open = false; 
    
    # 启用 NVIDIA 设置面板
    nvidiaSettings = true;

    # 选择驱动版本
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # 桌面端建议关闭细粒度电源管理以榨取最大性能
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  # NVIDIA 环境变量 - 深度适配 Wayland (Hyprland)
  environment.sessionVariables = {
    # 核心渲染路径
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    
    # 启用应用在 Wayland 下的硬件加速
    NIXOS_OZONE_WL = "1";
    
    # 修复常见 UI 渲染问题
    WLR_NO_HARDWARE_CURSORS = "1"; 
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    
    # NVIDIA 专属性能优化
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    
    # CUDA 缓存路径
    CUDA_CACHE_PATH = "$HOME/.cache/nv";
  };
}
