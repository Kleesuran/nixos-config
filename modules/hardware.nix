{ pkgs, ... }:

{
  # 1. 启用 NetworkManager 管理网络
  networking.networkmanager.enable = true;
  # 确保 Wi-Fi 开机即启用
  networking.networkmanager.wifi.powersave = false; # 关闭节能模式，提升 AX210 稳定性

  # 2. 启用蓝牙支持
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # 开机自动激活蓝牙 (已启用)
    settings = {
      General = {
        Experimental = true; # 开启实验性功能，提升某些蓝牙设备兼容性
      };
    };
  };
  # 蓝牙管理工具
  services.blueman.enable = true;

  # 3. 硬件固件与驱动 (AX210 必需)
  hardware.enableRedistributableFirmware = true;
  boot.kernelModules = [ "iwlwifi" ]; # 显式加载 Intel 无线网卡驱动
}
