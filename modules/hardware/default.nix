# 通用硬件服务（任意 x86_64 机器都成立）
# 本机专属的 CPU/GPU/磁盘/唤醒策略放在 hosts/<name>/
{
  imports = [
    ./audio.nix
    ./audio-lhdc.nix
    ./bluetooth.nix
    ./network.nix
  ];

  # 台式机与笔记本都需要；与 CPU 厂商无关，所以不放在主机目录。
  services.power-profiles-daemon.enable = true;
}
