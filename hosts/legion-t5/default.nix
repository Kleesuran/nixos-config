# legion-t5 主机装配
# 只做「选哪些模块」和主机级参数，不写具体配置
{ ... }:

{
  imports = [
    ./hardware.nix
    ./disk.nix
    ./boot.nix

    ../../modules/core
    ../../modules/hardware
    ../../modules/desktop
    ../../modules/apps
    ../../modules/services
    ../../modules/security
  ];

  networking.hostName = "legion-t5";

  system.stateVersion = "26.05";
}
