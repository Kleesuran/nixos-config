{ pkgs, config, lib, ... }:

let
  # 使用 MetaCubeXD 作为前端控制面板
  metacubexd = pkgs.fetchzip {
    url = "https://github.com/MetaCubeX/MetaCubeXD/releases/download/v1.171.0/compressed-dist.zip";
    hash = "sha256-6mFhV+BInM16S0rB8zV8G4+j9WInhRkYfV/I9Z4S8Qo=";
  };
in
{
  # 1. 核心内核模块
  boot.kernelModules = [ "tun" ];
  
  # 2. 注入 Geo 数据库 (修复报错的关键)
  # 在新版 Nixpkgs 中，请统一使用这些包名
  environment.etc = {
    "mihomo/geoip.dat".source = "${pkgs.v2ray-geoip}/share/v2ray/geoip.dat";
    "mihomo/geosite.dat".source = "${pkgs.v2ray-domain-list-community}/share/v2ray/geosite.dat";
    "mihomo/ui".source = metacubexd;
  };

  # 3. 网络与防火墙
  networking.firewall = {
    enable = true;
    checkReversePath = false; # TUN 模式必需，否则流量无法返回
    allowedTCPPorts = [ 9090 7890 ]; 
    allowedUDPPorts = [ 7890 ];
  };

  # 4. 权限封装 (必须通过 wrapper 才能使用网卡管理权限)
  security.wrappers.mihomo = {
    owner = "root";
    group = "root";
    source = "${pkgs.mihomo}/bin/mihomo";
    capabilities = "cap_net_admin,cap_net_bind_service+ep";
  };

  # 5. Systemd 服务修复
  systemd.services.mihomo = {
    description = "Mihomo (Clash Meta) Daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    # 启动前检查并生成基础配置
    preStart = ''
      mkdir -p /etc/mihomo
      if [ ! -f /etc/mihomo/config.yaml ]; then
        cat <<EOF > /etc/mihomo/config.yaml
mixed-port: 7890
external-controller: 0.0.0.0:9090
external-ui: ui
dns:
  enable: true
  enhanced-mode: fake-ip
  nameserver: [223.5.5.5, 119.29.29.29]
tun:
  enable: true
  stack: system
  auto-route: true
  auto-detect-interface: true
EOF
      fi
    '';

    serviceConfig = {
      # 重点：使用 wrapper 路径，并指向 /etc/mihomo
      ExecStart = "/run/wrappers/bin/mihomo -d /etc/mihomo";
      Restart = "always";
      User = "root";
      # 允许读写配置目录以便更新数据库
      ReadWritePaths = [ "/etc/mihomo" ];
    };
  };
}