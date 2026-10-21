#!/usr/bin/env bash
# 从 Arch 直接把 NixOS 装到 @nixos / @nix / @boot
# 不碰 Arch 的 @ 与 @home，失败可直接从原 GRUB 条目回退
set -euo pipefail

DISK=/dev/nvme0n1p1
ESP=/dev/sdb1
TARGET=/mnt
REPO=/mnt/repos/nixos-config

msg() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m错误: %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- 前置检查
msg "前置检查"
mountpoint -q /nix || die "/nix 未挂载（先跑 prepare-nix.sh）"
[ -f "$REPO/flake.nix" ] || die "找不到 $REPO"

# Arch 上没有 nixos-install，从 store 里取
NIXOS_INSTALL_PKG=$(/usr/bin/nix build --no-link --print-out-paths nixpkgs#nixos-install)
NIXOS_ENTER_PKG=$(/usr/bin/nix build --no-link --print-out-paths nixpkgs#nixos-enter)
export PATH="$NIXOS_INSTALL_PKG/bin:$NIXOS_ENTER_PKG/bin:$PATH"

if mountpoint -q "$TARGET"; then die "$TARGET 已被占用"; fi

# @nixos 必须是空的，防止覆盖已有安装
mkdir -p /tmp/nixos-check
mount -o subvol=@nixos "$DISK" /tmp/nixos-check
if [ -n "$(ls -A /tmp/nixos-check)" ]; then
  umount /tmp/nixos-check
  die "@nixos 非空，已存在安装，终止"
fi
umount /tmp/nixos-check
rmdir /tmp/nixos-check
echo "    @nixos 为空，可以安装"

# ---------------------------------------------------------------- 挂载目标
msg "挂载目标子卷"
SSD_OPTS=compress=zstd:3,noatime,ssd,discard=async
mount -o "subvol=@nixos,$SSD_OPTS" "$DISK" "$TARGET"
mkdir -p "$TARGET"/{nix,boot,home,efi,mnt,var/lib}
mount -o "subvol=@nix,$SSD_OPTS"   "$DISK" "$TARGET/nix"
mount -o "subvol=@boot,$SSD_OPTS"  "$DISK" "$TARGET/boot"
mount -o "subvol=@home,$SSD_OPTS"  "$DISK" "$TARGET/home"
mount "$ESP" "$TARGET/efi"
for sv in steam containers repos vms; do
  mkdir -p "$TARGET/mnt/$sv"
  mount -o "subvol=@$sv,$SSD_OPTS" "$DISK" "$TARGET/mnt/$sv"
done
findmnt -R "$TARGET" -o TARGET,SOURCE,FSTYPE | sed 's/^/    /'

# ---------------------------------------------------------------- 密钥
msg "恢复 Secure Boot 密钥"
mkdir -p "$TARGET/var/lib/sbctl"
if [ -d /var/lib/sbctl/keys ]; then
  cp -a /var/lib/sbctl/keys "$TARGET/var/lib/sbctl/"
elif [ -d /mnt/repos/sbctl_backup/keys ]; then
  cp -a /mnt/repos/sbctl_backup/keys "$TARGET/var/lib/sbctl/"
else
  die "找不到 sbctl 密钥（/var/lib/sbctl/keys）"
fi
chmod -R go-rwx "$TARGET/var/lib/sbctl/keys"
echo "    db.key 校验: $(sha256sum "$TARGET/var/lib/sbctl/keys/db/db.key" | cut -c1-16)…"

# ---------------------------------------------------------------- 安装
msg "nixos-install（使用已预热的 /nix store）"
nixos-install --flake "$REPO#legion-t5" --no-root-passwd

# ---------------------------------------------------------------- 密码
msg "同步 klee 的密码哈希"
HASH=$(getent shadow klee | cut -d: -f2)
if [ -n "$HASH" ] && [ "${HASH:0:1}" != "!" ]; then
  mkdir -p "$TARGET/tmp"
  printf 'klee:%s\n' "$HASH" > "$TARGET/tmp/klee.pw"
  nixos-enter --root "$TARGET" -c 'chpasswd -e < /tmp/klee.pw && rm -f /tmp/klee.pw'
  echo "    已使用 Arch 现有密码"
else
  echo "    跳过（Arch 上的 klee 无可用密码哈希）"
fi

# ---------------------------------------------------------------- 验证
msg "验证引导器签名"
GRUB_EFI=$(find "$TARGET/efi/EFI" -maxdepth 2 -name grubx64.efi | grep -i nixos | head -1)
if [ -n "$GRUB_EFI" ]; then
  echo "    找到: ${GRUB_EFI#$TARGET}"
  sbverify --list "$GRUB_EFI" | sed 's/^/    /'
else
  echo "    ！未找到 NixOS 的 grubx64.efi"
fi

msg "EFI 启动项"
efibootmgr | sed 's/^/    /'

cat <<EOF

安装完成。重启前请注意：
  1. 固件启动顺序里找 "NixOS-efi"（不是 GRUB）作为第一项；
  2. 首次启动若失败，用 F12 选回 GRUB 进 Arch，数据未动；
  3. 卸载目标：sudo umount -R $TARGET

重启后可执行：
  sudo reboot
EOF
