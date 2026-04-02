{ config, pkgs, ... }:

{
  # 1. 这里的 boot 是顶级的，不要缩进到 networking 里面
  boot.kernelModules = [ "tun" ];

  # 2. 网络相关的配置
  networking.firewall = {
    enable = true;

    # 允许 LocalSend 端口
    allowedTCPPorts = [ 53317 7890 9090 ];
    allowedUDPPorts = [ 53317 7890 ];

    # 允许 TUN 模式流量
    checkReversePath = false;
  };
}
