{ pkgs, ... }:

{
  # 确保系统防火墙基础功能开启
  networking.firewall.enable = true;

  # 定义手动控制的服务
  systemd.services.devops-ports = {
    description = "Open ports for DevOps experiments (Manual Toggle)";
    
    # 路径中包含 iptables 确保指令可用
    path = [ pkgs.iptables ];

    # 启动时：在 INPUT 链的最前面插入允许规则 (Insert at position 1)
    # 包含端口：3000-3010 (前端), 5432 (PG), 6379 (Redis), 8080 (Jenkins/Backends), 9000 (Tools), 6443 (K8s)
    script = ''
      iptables -I INPUT 1 -p tcp --match multiport --dports 3000:3010,5432,6379,8080,9000,6443 -j ACCEPT -m comment --comment "devops-lab-manual"
      echo "DevOps lab ports (3000:3010, 5432, 6379, 8080, 9000, 6443) are now OPEN."
    '';

    # 停止时：删除该规则
    preStop = ''
      iptables -D INPUT -p tcp --match multiport --dports 3000:3010,5432,6379,8080,9000,6443 -j ACCEPT
      echo "DevOps lab ports are now CLOSED."
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true; # 保持服务为 Active 状态直到手动 Stop
      User = "root";
    };

    # 关键：不设置 [Install] 块中的 wantedBy，所以它不会被 enable
  };
}
