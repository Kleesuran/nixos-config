{ pkgs, ... }:

{
  # 1. 启用 NetworkManager 管理网络
  networking.networkmanager.enable = true;

  # 2. 启用蓝牙支持
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # 开机自动激活蓝牙
  };
  # 蓝牙管理工具 (如果你需要的话)
  services.blueman.enable = true;

  # 3. 关键：启用非自由固件支持 (绝大多数笔记本 Wi-Fi/蓝牙网卡必需)
  hardware.enableRedistributableFirmware = true;
}
