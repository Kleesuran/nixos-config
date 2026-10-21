# 恢复手册（2026-10-21 安装后）

> 这份文件的副本放在 U 盘根目录：`/run/media/klee/KIOXIA/nixos/先读我-恢复手册.md`
> 系统起不来时，用手机或另一台机器打开它。

## 一、这次做了什么

- 在 Arch 运行期间，把 NixOS 安装到同一块 NVMe 的新子卷，未重装、未缩小分区。
- Arch 的 `@`、`@home` 原封不动，仍在 GRUB 菜单里可启动。
- 新引导器 `EFI/NixOS-efi/grubx64.efi` 用原有 sbctl 的 `Database Key` 签名，Secure Boot 保持开启。
- 固件 BootOrder 现在是：`NixOS-efi` → `GRUB`(Arch) → `Windows Boot Manager`。
- 写入 `/efi/dsdt.aml`，Windows 条目通过 GRUB 的 `acpi` 命令注入，修复 TC-O4M 主板 `PEGP._DSM` 死循环。
- Linux 侧通过 initrd 前段的未压缩 cpio 注入同一张 DSDT，避免开机 30 秒卡顿。

## 二、磁盘与 UUID

| 设备 | UUID | 用途 |
|---|---|---|
| nvme0n1p1 | `724b4e5f-3e76-4ac0-8ed7-ea74201deee2` | btrfs 全部系统与数据 |
| sdb1 | `9C35-4F77` | ESP（`/efi`） |
| sdb3 | `D834B86134B843F2` | Windows C:（`/mnt/windows`） |
| sdb5 | `3C78365578360E60` | NTFS 数据（`/mnt/data`） |
| sda1 | `1F3368C53EC749BF` | HDD 备份（`/mnt/HDD`） |

子卷：

| 子卷 | 挂载点 | 归属 |
|---|---|---|
| `@nixos` | `/` | NixOS 根 |
| `@nix` | `/nix` | Nix store（与 Arch 共用，已预热） |
| `@boot` | `/boot` | 内核、initrd、grub.cfg |
| `@home` | `/home` | **与 Arch 共用** |
| `@steam` `@containers` `@repos` `@vms` | `/mnt/steam` 等 | 与 Arch 共用 |
| `@` `@pkg` `@log` | — | Arch 根，验收后再删 |

## 三、起不来时的第一反应

1. **先别重装。** 开机按 `F12`，选 `GRUB`，进 Arch。数据全在。
2. 如果能进 GRUB 菜单但 NixOS 起不来，按 `e` 编辑启动项，在 `linux` 行末尾加参数：
   - NVIDIA 黑屏：`nomodeset`
   - 想进文本模式排查：`systemd.unit=multi-user.target`
   按 `Ctrl+X` 启动。
3. 如果连 GRUB 都不出现，进 BIOS 把 Secure Boot 临时关掉再试；关掉不影响 Windows（未加密）。

## 四、从 Live 环境修复

假设用 NixOS 或 Arch 的 Live USB，设备名以 `lsblk` 为准。

```bash
sudo mount -o subvol=@nixos /dev/nvme0n1p1 /mnt
sudo mkdir -p /mnt/{nix,boot,home,efi}
sudo mount -o subvol=@nix /dev/nvme0n1p1    /mnt/nix
sudo mount -o subvol=@boot /dev/nvme0n1p1   /mnt/boot
sudo mount -o subvol=@home /dev/nvme0n1p1   /mnt/home
sudo mount /dev/sdb1 /mnt/efi
```

### 重新生成 grub.cfg / 重装引导器

```bash
sudo nixos-enter --root /mnt -c 'switch-to-configuration boot'
```

这会重新跑 grub-install，并在 `extraInstallCommands` 里自动用
`/var/lib/sbctl/keys/db/db.key` 重新签名。

### 手动签名（如果自动签名失败）

```bash
sudo sbsign --key /var/lib/sbctl/keys/db/db.key \
            --cert /var/lib/sbctl/keys/db/db.pem \
            --output /mnt/efi/EFI/NixOS-efi/grubx64.efi \
                     /mnt/efi/EFI/NixOS-efi/grubx64.efi
```

### 密钥丢了

U 盘备份：`/run/media/klee/KIOXIA/ARCH_MIGRATION_BACKUP_20261001/sbctl_backup/keys`
恢复到 `/mnt/var/lib/sbctl/keys`，权限 `700`，`*.key` 为 `600`。

### 从 U 盘重装

配置仓库在 `U盘/nixos/nixos-config`。先把它挂到 `/mnt/repos/nixos-config`
（或直接 `nixos-install --flake /run/media/.../nixos-config#legion-t5`），
再执行：

```bash
sudo nixos-install --flake /path/to/nixos-config#legion-t5
```

注意：`/nix` 里已有预热好的闭包，重装只需几十秒。

## 五、回退到 Arch

临时：开机 F12 → `GRUB`。

永久（把 Arch 放回第一顺位）：

```bash
sudo efibootmgr -o 0006,0003,0000
```

确认不再需要 NixOS 后，再删子卷（不可逆）：

```bash
sudo mount -o subvolid=5 /dev/nvme0n1p1 /mnt
sudo btrfs subvolume delete /mnt/@nixos /mnt/@nix /mnt/@boot
```

## 六、常见症状对照

| 症状 | 原因 | 处理 |
|---|---|---|
| GRUB 菜单出现，NixOS 停在黑屏 | NVIDIA KMS | 启动项加 `nomodeset` |
| 卡 30 秒后进系统，dmesg 有 `AE_AML_LOOP_TIMEOUT` | ACPI 表没注入 | 检查 `/boot/kernels/*initrd` 前段是否有 `dsdt.aml` |
| 提示 Secure Boot violation | GRUB 未签名 | 手动 sbsign，或临时关 SB |
| `root=fstab` 挂载失败进 emergency | 子卷没建/挂载参数错 | 检查子卷名与 `/etc/fstab` |
| 无法登录 | shadow 没密码 | Live 里改 `/mnt/etc/shadow` 或用 `passwd` |
| Windows 蓝屏/黑屏 | 走了非注入条目 | 必须用 `Windows 10/11 (ACPI Inject)` |

## 七、把这段发给 AI 继续排查

```text
机器：Lenovo Legion T5 26AMR5，Ryzen 7 3700X，RTX 2070 Max-Q（独显无核显），
32G 内存，Secure Boot 开启，db 里有自签的 "Database Key"。
2026-10-21 从 Arch 安装了 NixOS 到 nvme0n1p1 的 @nixos 子卷，
配置仓库在 U 盘 nixos/nixos-config（也在 /mnt/repos/nixos-config）。
@nix / @boot 独立子卷，/efi 是 sdb1（9C35-4F77），
启动器是 /efi/EFI/NixOS-efi/grubx64.efi，用 db 密钥签名。
ACPI 补丁 dsdt.aml 已复制到 /efi/dsdt.aml，Linux 侧用 boot.initrd.prepend 注入。

现在的现象是：<在这里写你看到的画面 / 报错原文>
我已经试过：<写你试过的步骤>
请给我下一步的排查命令，尽量只读，不要直接改分区。
```

## 八、配置仓库

- U 盘副本：`/run/media/klee/KIOXIA/nixos/nixos-config`
- 机器上：`/mnt/repos/nixos-config`（btrfs `@repos`，和 Arch 共用）
- 校验：`cd nixos-config && git log --oneline`
- 关键模块：`hosts/legion-t5/boot.nix`（引导/ACPI）、`modules/security/secureboot.nix`（签名）、
  `hosts/legion-t5/disk.nix`（子卷）

U 盘是 exFAT，两个限制：

1. **脚本没有执行位**，要写成 `bash scripts/install-from-arch.sh`，不要 `./`。
2. **不支持符号链接**，仓库里的 `result` 软链已排除，不影响求值。

Live 环境里 U 盘挂载点通常不是 `/run/media/klee`，先找盘：

```bash
lsblk -f | grep -i exfat      # 117G 的 KIOXIA
sudo mkdir -p /mnt/usb && sudo mount /dev/sdX1 /mnt/usb
cd /mnt/usb/nixos/nixos-config
```

直接用它安装：

```bash
sudo nixos-install --flake /mnt/usb/nixos/nixos-config#legion-t5
```

