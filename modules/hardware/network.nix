# 网络：NetworkManager（iwd 后端）+ firewalld 的替代 nftables
{ lib, ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    wireless.iwd.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        6443 # k3s API
        53317 # LocalSend（传输）
        7890 # mihomo mixed-port
        8080 # 可选 LAN 代理
      ];
      allowedUDPPorts = [
        53317 # LocalSend（组播发现 + 传输）
      ];
      trustedInterfaces = [
        "cni0"
        "flannel.1"
      ];
    };
  };

  # iwd 与 NM 都需要 DHCP，交给 NM
  networking.useDHCP = lib.mkDefault true;
}
