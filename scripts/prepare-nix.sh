#!/usr/bin/env bash
# 在 Arch 上为 NixOS 预构建做准备（只做一次）
#   sudo bash scripts/prepare-nix.sh
set -euo pipefail

DISK=/dev/nvme0n1p1
UUID=724b4e5f-3e76-4ac0-8ed7-ea74201deee2

echo "==> 1/5 创建子卷 @nix / @nixos / @boot"
mkdir -p /mnt/btrfs-top
mountpoint -q /mnt/btrfs-top || mount -o subvolid=5 "$DISK" /mnt/btrfs-top
for sv in @nix @nixos @boot; do
  if [ -d "/mnt/btrfs-top/$sv" ]; then
    echo "    已存在: $sv"
  else
    btrfs subvolume create "/mnt/btrfs-top/$sv"
  fi
done
umount /mnt/btrfs-top
rmdir /mnt/btrfs-top

echo "==> 2/5 挂载 @nix 到 /nix"
mkdir -p /nix
if ! mountpoint -q /nix; then
  mount -o "subvol=@nix,compress=zstd:3,noatime,ssd,discard=async" "$DISK" /nix
fi
if ! grep -q "subvol=@nix" /etc/fstab; then
  printf 'UUID=%s /nix btrfs subvol=@nix,compress=zstd:3,noatime,ssd,discard=async,nofail 0 0\n' \
    "$UUID" >> /etc/fstab
  echo "    已写入 /etc/fstab"
fi
findmnt -no TARGET,SOURCE,OPTIONS /nix

echo "==> 3/5 安装 nix"
pacman -S --needed --noconfirm nix

echo "==> 4/5 写入 /etc/nix/nix.conf"
mkdir -p /etc/nix
[ -f /etc/nix/nix.conf ] && cp /etc/nix/nix.conf "/etc/nix/nix.conf.bak.$(date +%s)"
cat > /etc/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
trusted-users = root @wheel
substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
max-jobs = auto
cores = 0
EOF

echo "==> 5/5 启动 nix-daemon"
systemctl enable --now nix-daemon
systemctl restart nix-daemon
sleep 1

nix --version
systemctl is-active nix-daemon
echo "完成。接下来可以运行: nix build /mnt/repos/nixos-config#nixosConfigurations.legion-t5.config.system.build.toplevel"
