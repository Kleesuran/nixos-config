{ pkgs, ... }:

{
  # 启用 daed 服务 (基于 eBPF 的高性能透明代理)
  services.daed = {
    enable = true;
  };

  # 开放 Web 控制面板端口 (默认 2023)
  networking.firewall.allowedTCPPorts = [ 2023 ];

  # 系统级安装 daed 软件包
  environment.systemPackages = [ pkgs.daed ];
}
