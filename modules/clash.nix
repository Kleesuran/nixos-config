{ pkgs, ... }:

{
  # 1. 确保内核开启了 TUN 模块
  boot.kernelModules = [ "tun" ];

  # 2. 允许非 NixOS 原生二进制文件运行 (FlClash 内部内核需要)
  programs.nix-ld.enable = true;

  # 3. 关闭防火墙的反向路径过滤 (TUN 模式必需)
  # 否则流量会被标记为非法包而被系统丢弃
  networking.firewall.checkReversePath = false;

  # 4. 为 FlClash 注入网卡管理权限 (关键步骤)
  # 这会生成一个位于 /run/wrappers/bin/FlClash 的特殊执行文件
  security.wrappers.FlClash = {
    owner = "root";
    group = "root";
    source = "${pkgs.flclash}/bin/FlClash";
    capabilities = "cap_net_admin,cap_net_bind_service+ep";
  };
}
