# nixos-config

Legion T5（Ryzen 7 3700X / RTX 2070 Max-Q）的 NixOS 配置。
与 Arch、Windows 三系统共存，共用同一块 btrfs 上的数据子卷。

## 结构

```
flake.nix                    # 装配：nixpkgs + home-manager
hosts/legion-t5/
  default.nix                # 选模块 + hostName
  hardware.nix               # CPU/内核模块/zram
  disk.nix                   # btrfs 子卷 + NTFS
  boot.nix                   # GRUB、ACPI 注入、Secure Boot 菜单
modules/
  core/                      # nix、locale、users
  hardware/                  # cpu、nvidia、audio、bluetooth、network
  desktop/                   # plasma、fonts、input-method、hyprland(可选)
  apps/                      # dev、gaming、chinese
  services/                  # k3s、proxy、printing
  security/                  # Secure Boot 重签
home/klee/                   # home-manager（只做新增，不覆盖 Arch 的文件）
firmware/dsdt.aml            # TC-O4M 主板 ACPI 修复表
```

## 子卷

| 子卷 | 挂载点 | 归属 |
|---|---|---|
| `@nixos` | `/` | NixOS 新建 |
| `@nix` | `/nix` | NixOS 新建 |
| `@boot` | `/boot` | NixOS 新建 |
| `@home` | `/home` | 与 Arch 共用 |
| `@steam` `@containers` `@repos` `@vms` | `/mnt/*` | 与 Arch 共用 |
| `@` | — | Arch 根，验收后删除 |

ESP（`sdb1`）挂 `/efi`，只放 `grubx64.efi` 与 `dsdt.aml`，内核在 `@boot`。

## 安装

前提：Secure Boot 的密钥已备份在 `/var/lib/sbctl/keys`（U 盘
`ARCH_MIGRATION_BACKUP_20261001/sbctl_backup/keys`）。

### 1. 在 Arch 上预热（可选但强烈建议）

```bash
sudo mount -o subvolid=5 /dev/nvme0n1p1 /mnt
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@nixos
sudo btrfs subvolume create /mnt/@boot
sudo umount /mnt

sudo mkdir -p /nix
sudo mount -o subvol=@nix,compress=zstd:3,noatime /dev/nvme0n1p1 /nix
echo 'UUID=724b4e5f-3e76-4ac0-8ed7-ea74201deee2 /nix btrfs subvol=@nix,compress=zstd:3,noatime 0 0' | sudo tee -a /etc/fstab

sudo pacman -S nix
sudo systemctl enable --now nix-daemon
sudo tee /etc/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
trusted-users = root @wheel
substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org
EOF
sudo systemctl restart nix-daemon

nix build /mnt/repos/nixos-config#nixosConfigurations.legion-t5.config.system.build.toplevel --no-link
```

### 2. 从 Live USB 安装

```bash
# 确认 btrfs 默认子卷仍是顶层，避免 mount 找不到
sudo mount -o subvolid=5 /dev/nvme0n1p1 /mnt
ls /mnt            # 应能看到 @ @home @nixos @nix @boot
sudo umount /mnt

sudo mount -o subvol=@nixos,compress=zstd:3,noatime /dev/nvme0n1p1 /mnt
sudo mkdir -p /mnt/{nix,boot,home,efi,mnt}
sudo mount -o subvol=@nix,compress=zstd:3,noatime /dev/nvme0n1p1 /mnt/nix
sudo mount -o subvol=@boot,compress=zstd:3,noatime /dev/nvme0n1p1 /mnt/boot
sudo mount -o subvol=@home,compress=zstd:3,noatime /dev/nvme0n1p1 /mnt/home
sudo mount /dev/sdb1 /mnt/efi
sudo mount -o subvol=@steam /dev/nvme0n1p1 /mnt/mnt/steam
sudo mount -o subvol=@containers /dev/nvme0n1p1 /mnt/mnt/containers
sudo mount -o subvol=@repos /dev/nvme0n1p1 /mnt/mnt/repos
sudo mount -o subvol=@vms /dev/nvme0n1p1 /mnt/mnt/vms

sudo mkdir -p /mnt/var/lib/sbctl
sudo cp -a /path/to/sbctl_backup/keys /mnt/var/lib/sbctl/keys

sudo nixos-generate-config --root /mnt --no-filesystems
# 用它覆盖 hosts/legion-t5/hardware.nix 中的内核模块部分，不要覆盖 disk.nix

sudo nixos-install --flake /mnt/mnt/repos/nixos-config#legion-t5 --no-root-passwd
```

首次启动后设置用户密码：`sudo passwd klee`。

## 验收清单

- [ ] 开机无 30 秒卡顿，`dmesg | grep -c AE_AML_LOOP` 为 0
- [ ] `sudo sbctl verify` 全部 signed，`systemctl status sign-grub` 成功
- [ ] `nvidia-smi` 正常，Plasma Wayland 会话可登录
- [ ] 声音、Wi-Fi、蓝牙耳机、打印机
- [ ] fcitx5 输入法（Rime）可切换
- [ ] Steam 添加 `/mnt/steam/SteamLibrary` 后游戏可启动
- [ ] `kubectl get nodes` 为 Ready
- [ ] Windows 菜单项能进系统且显卡驱动正常（ACPI 注入生效）

## 回退

未删除 `@` 之前，GRUB 菜单里的 “Arch Linux (legacy)” 可回 Arch。
验收全部通过后再执行：

```bash
sudo mount -o subvolid=5 /dev/nvme0n1p1 /mnt
sudo btrfs subvolume delete /mnt/@ /mnt/@pkg /mnt/@log
# @home 与 @steam 等是共用的，不要删
```
