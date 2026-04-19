{ config, lib, ... }:

with lib;

{
  options.klee = {
    gpu = {
      type = mkOption {
        type = types.enum [ "nvidia" "amd" "intel" "none" ];
        default = "none";
        description = "Which GPU driver family should be configured.";
      };
      cuda = mkEnableOption "NVIDIA CUDA and Container Toolkit support";
    };

    boot = {
      mode = mkOption {
        type = types.enum [ "chainload" "standalone" ];
        default = "standalone";
        description = ''
          - chainload: 由其他系统(如Fedora)引导，NixOS不修改EFI变量。
          - standalone: NixOS作为主系统，接管引导并开启 OS Prober。
        '';
      };
      efiSysMountPoint = mkOption {
        type = types.str;
        default = "/boot";
      };
    };

    storage = {
      isKlee2070m = mkEnableOption "Klee's RTX 2070 Mobile specific storage layout";
    };

    daed = {
      enable = mkEnableOption "daed network proxy service";
      useFallback = mkEnableOption "Zero-Network Fallback mode (uses local binary)";
    };
  };

  config = {
    # 自动映射到现有模块的选项
    drivers.graphics = {
      enable = config.klee.gpu.type != "none";
      gpuType = config.klee.gpu.type;
    };

    drivers.cuda.enable = config.klee.gpu.cuda;

    device.klee-2070m.enable = config.klee.storage.isKlee2070m;

    bootloaders.nixosGrub = {
      enable = true;
      canTouchEfiVariables = config.klee.boot.mode == "standalone";
      efiSysMountPoint = config.klee.boot.efiSysMountPoint;
      useOSProber = config.klee.boot.mode == "standalone";
    };
  };
}
