{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.drivers.cuda;
  graphicsCfg = config.drivers.graphics;
in
{
  options.drivers.cuda = {
    enable = mkEnableOption "NVIDIA CUDA and Container Toolkit support";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = graphicsCfg.gpuType == "nvidia";
        message = "drivers.cuda.enable 仅在 drivers.graphics.gpuType = \"nvidia\" 时支持。";
      }
    ];

    # CUDA 模块只负责计算栈，不再混入游戏图形配置。
    hardware.nvidia-container-toolkit.enable = true;

    environment.systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
    ];
  };
}
