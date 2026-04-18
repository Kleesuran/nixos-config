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

  config = mkIf (cfg.enable && graphicsCfg.gpuType == "nvidia") {
    # 启用 NVIDIA Container Toolkit (CDI)
    # 允许 Podman 和 Docker 容器直接调用 NVIDIA GPU 进行 AI 推理或计算
    hardware.nvidia-container-toolkit.enable = true;

    # 同时也为宿主机提供基础的 CUDA 运行库支持
    # 这样可以在不进入容器的情况下运行简单的 GPU 程序
    environment.systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
    ];

    # 针对 Podman 的额外优化 (由于您在 system.nix 中启用了 Podman)
    virtualisation.podman.enable = true;
  };
}
