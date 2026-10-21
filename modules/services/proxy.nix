# mihomo TUN 模式透明代理
# 配置文件不入库：放在 /etc/mihomo/config.yaml（首次用 activation 外的命令部署）
{ pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /etc/mihomo 0750 root root -"
  ];

  systemd.services.mihomo = {
    description = "mihomo (Clash Meta) transparent proxy";
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
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
