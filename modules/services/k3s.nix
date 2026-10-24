# 单节点 k3s（原机已跑 138 天，数据在 /var/lib/rancher）
{ config, ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--write-kubeconfig-mode=0644"
    ];
  };

  environment.systemPackages = [ config.services.k3s.package ];

  networking.firewall = {
    allowedTCPPorts = [ 6443 ];
    trustedInterfaces = [
      "cni0"
      "flannel.1"
    ];
  };
}
