{ pkgs, ... }:

{
  # 1. 核心网络功能支持 (TUN 模式)
  boot.kernelModules = [ "tun" ];
  
  # 2. 允许非 NixOS 原生二进制文件运行 (FlClash/Mihomo/Sing-box 内部核心及 DevOps 工具需要)
  programs.nix-ld.enable = true;

  # 3. 防火墙配置
  networking.firewall = {
    enable = true;
    
    # 允许 TUN 模式流量 (关闭反向路径过滤，防止流量被丢弃)
    checkReversePath = false;

    # 允许常用应用端口
    # 53317: LocalSend
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];

    # 学习容器 (Podman/Docker) 开发专用端口范围
    # 开放 8000 到 9000，解决每次都要改配置文件的问题
    allowedTCPPortRanges = [ 
      { from = 8000; to = 9000; } 
    ];
    allowedUDPPortRanges = [ 
      { from = 8000; to = 9000; } 
    ];
  };

  # 4. 为代理工具注入网卡管理权限 (TUN 模式必需)
  # 这会生成对应的包装程序，使其有权在非 root 权限下操作网卡
  security.wrappers = {
    FlClash = {
      owner = "root";
      group = "root";
      source = "${pkgs.flclash}/bin/FlClash";
      capabilities = "cap_net_admin,cap_net_bind_service+ep";
    };
    mihomo = {
      owner = "root";
      group = "root";
      source = "${pkgs.mihomo}/bin/mihomo";
      capabilities = "cap_net_admin,cap_net_bind_service+ep";
    };
    sing-box = {
      owner = "root";
      group = "root";
      source = "${pkgs.sing-box}/bin/sing-box";
      capabilities = "cap_net_admin,cap_net_bind_service+ep";
    };
  };
}
