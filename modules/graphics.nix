{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.drivers.graphics;
in
{
  options.drivers.graphics = {
    enable = mkEnableOption "Graphics support";
    gpuType = mkOption {
      type = types.enum [ "nvidia" "amd" "intel" "none" ];
      default = "none";
      description = "Choose which GPU driver to enable";
    };
  };

  config = mkIf cfg.enable {
    # 1. 基础图形支持 (通用)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        # 通用硬件加速
        libva-vdpau-driver
        libvdpau-va-gl
      ] ++ (if cfg.gpuType == "intel" then [
        # Intel 专属加速 (适用于第8代及以后)
        intel-media-driver
        vaapiIntel
      ] else if cfg.gpuType == "amd" then [
        # AMD 专属加速 (新架构)
        libvdpau
        vaapiVdpau
      ] else if cfg.gpuType == "nvidia" then [
        # NVIDIA 专属加速
        nvidia-vaapi-driver
      ] else []);
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva-vdpau-driver
        libvdpau-va-gl
      ] ++ (if cfg.gpuType == "nvidia" then [
        nvidia-vaapi-driver
      ] else []);
    };

    # 2. NVIDIA 专属配置
    services.xserver.videoDrivers = mkIf (cfg.gpuType == "nvidia") [ "nvidia" ];
    hardware.nvidia = mkIf (cfg.gpuType == "nvidia") {
      modesetting.enable = true;
      open = true; 
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = false;
    };

    # 3. AMD 专属配置 (通常由内核直接支持，但需要开启某些参数)
    # 对于 AMD，主要配置通常已在 boot.kernelParams 中完成
  };
}
