# mihomo（Clash Meta）透明代理
# 配置不入库：/etc/mihomo/config.yaml 由 `mihomo-try` 校验后部署
# TUN 由配置文件的 tun: 段开启，服务已授予 CAP_NET_ADMIN
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.mihomo ];

  # TUN 模式（/dev/net/tun）：确保开机加载 tun 模块
  boot.kernelModules = [ "tun" ];

  systemd.tmpfiles.rules = [
    "d /etc/mihomo 0750 root root -"
  ];

  systemd.services.mihomo = {
    description = "mihomo (Clash Meta) transparent proxy";
    documentation = [ "https://wiki.metacubex.one/" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    unitConfig.ConditionPathExists = "/etc/mihomo/config.yaml";

    serviceConfig = {
      ExecStart = "${pkgs.mihomo}/bin/mihomo -d /etc/mihomo -f /etc/mihomo/config.yaml";
      Restart = "on-failure";
      RestartSec = 5;

      AmbientCapabilities = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
        "CAP_NET_BIND_SERVICE"
      ];
      CapabilityBoundingSet = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
        "CAP_NET_BIND_SERVICE"
      ];

      LimitNOFILE = 65535;
      NoNewPrivileges = true;
      UMask = "0077";
    };
  };

  # mixed-port 与可选 LAN 代理端口随服务一起开放
  networking.firewall.allowedTCPPorts = [
    7890
    8080
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
