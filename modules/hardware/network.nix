# 网络：NetworkManager（iwd 后端）+ 防火墙
#
# 这里只保留所有主机都成立的设置。具体端口由需要它的服务自己开：
# k3s（6443 + cni 接口）、mihomo（7890/8080）、LocalSend（53317）。
{ lib, ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    wireless.iwd.enable = true;

    firewall.enable = true;
  };

  # iwd 与 NM 都需要 DHCP，交给 NM
  networking.useDHCP = lib.mkDefault true;
}
