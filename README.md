# nixos-config

Legion T5（Ryzen 7 3700X / RTX 2070 Max-Q）的 NixOS 配置。
与 Arch、Windows 三系统共存，共用同一块 btrfs 上的数据子卷。

## 结构

```
flake.nix                    # 装配：nixpkgs + home-manager
hosts/legion-t5/             # 主机层：只放本机硬件事实与策略
  default.nix                # 选模块 + hostName
  hardware.nix               # CPU/内核模块/zram
  disk.nix                   # btrfs 子卷 + NTFS
  boot.nix                   # GRUB、ACPI 注入、定制 core、Windows 菜单
  cpu-amd.nix                # AMD 启动参数
  gpu-nvidia.nix             # RTX 2070 驱动与 nvidia-smi 修补
  storage.nix                # 老 HDD 的块层设置
  wakeup.nix                 # 睡眠只留电源键唤醒
modules/                     # 通用层：任何 x86_64 主机可直接复用
  core/                      # nix、locale、users
  hardware/                  # audio、audio-lhdc、bluetooth、network（通用部分）
  desktop/                   # plasma、fonts、input-method、hyprland(end4-pC)
  apps/                      # dev、gaming、chinese
  services/                  # k3s、proxy、printing
  security/                  # Secure Boot 通用重签（ESP 路径自动推导）
home/klee/                   # home-manager（新增为主；Hyprland 配置从仓库接管）
pkgs/                        # 自打包：qoder-cn、qoder-cli、codebuddy、workbuddy、openuuyc、liblhdcv5、pipewire-lhdc…
firmware/                    # 本机专用：dsdt.aml 与定制 GRUB core
```

## 分层约定

- `hosts/<name>/`：`nixos-generate-config` 能生成的东西（磁盘、内核模块、CPU/GPU），
  以及绑定具体设备的选择（序列号、唤醒源、ACPI 表、引导器）。换个主机就整体替换。
- `modules/`、`home/`：与硬件无关的用户态。新增主机时直接复用，不需要改动；
  主机差异通过 `hosts/<name>/` 里的选择体现，而不是在通用模块里加 `if`。

## 子卷

| 子卷 | 挂载点 | 归属 |
|---|---|---|
| `@nixos` | `/` | NixOS 新建 |
| `@nix` | `/nix` | NixOS 新建 |
| `@boot` | `/boot` | NixOS 新建 |
| `@home` | `/home` | 与 Arch 共用 |
| `@steam` `@containers` `@repos` `@vms` | `/mnt/*` | 与 Arch 共用 |
| `@` `@pkg` `@log` | — | Arch 根/包缓存/日志，已于 2026-10-22 删除 |

ESP（`sdb1`）挂 `/efi`，只放 `grubx64.efi` 与 `dsdt.aml`，内核在 `@boot`。

## Hyprland / end4-pC

默认会话是 Hyprland + [end4-pC](https://github.com/pctrade/end4-pC)（illogical-impulse
分支），Plasma 保留为 SDDM 备用会话。

- `home/klee/hypr/`：Hyprland 本体配置（Lua），通过 out-of-store 软链到 `~/.config/hypr`。
  必须可写：end4 设置面板和 `switchwall.sh` 会实时改写 `shellOverrides/main.lua`、
  `hyprlock.conf`、`monitors.lua`、`colors.lua`。
- `home/klee/matugen/`、`fuzzel/`、`Kvantum/`：同样可写，取色和 Qt 主题会往里写。
- `xdg.configFile."quickshell/end4-pC"`：来自 flake input `end4-pC`，只读；
  个人补丁在 `pkgs/end4-pC/patches/0001-local-tweaks.patch`。
- nixpkgs 的 quickshell 默认不带 `Qt5Compat`、`org.kde.syntaxhighlighting`、
  `org.kde.kirigami` 等 QML 模块；`home/klee/hyprland.nix` 用 `makeWrapper`
  把这些模块的 `QML2_IMPORT_PATH` 补进 `qs`。
- Python 依赖由 `home/klee/hyprland.nix` 用 `python312.withPackages` 构建，
  软链到 `~/.local/state/quickshell/.venv`，不依赖 Arch 的 uv venv。
- 直接启动 Hyprland 不会拉起 `graphical-session.target`，所以
  `home/klee/hypr/hyprland/execs.lua` 会手动执行
  `systemctl --user start plasma-kwallet-pam.service`，用 SDDM PAM 的密码自动解锁
  kwallet。
- 鼠标指针使用 Arch 时期的 `MaterialDesignLight`，已复制到
  `home/klee/icons/MaterialDesignLight`，由 `home.pointerCursor` 装进 Nix store；
  Hyprland 的 `custom/env.lua` 和 `hyprctl setcursor` 都指向它，Plasma 的
  `kcminputrc` 由 HM activation 同步。
- polkit 认证代理由 `polkit-agent` 包装脚本按 `XDG_CURRENT_DESKTOP` 选择：
  Hyprland 用 `hyprpolkitagent`，Plasma 用 KDE 代理。一个会话只能注册一个代理。
- 壁纸选择与取色状态在 `~/.config/illogical-impulse/config.json` 和
  `~/.local/state/quickshell/`，属于本机状态，不放进仓库。
- 旧 Arch 配置备份在 `~/hypr-arch-backup-2026-10-24.tar.gz`。

修改 Hyprland 配置时直接改 `home/klee/hypr/`，然后重启 Hyprland（或 `hyprctl reload`）；
改 Nix 包/包版本时再 `nixos-rebuild switch`。

## 蓝牙 LHDC v5

`pkgs/liblhdcv5`（AOSP 编码器）+ `pkgs/pipewire-lhdc`（给 PipeWire 1.6.9 打上游
LHDC 补丁）+ `modules/hardware/audio-lhdc.nix`（把 `services.pipewire` 用到的
pipewire / wireplumber 换成这份构建）。没有覆盖全局 `pkgs.pipewire`，避免 kwin、
firefox 等依赖方全量重编译。

验证：

```bash
wpctl inspect <sink-id> | grep api.bluez5.codec   # 应为 "lhdc_v5"
grep lhdc /proc/$(pgrep -u klee -x wireplumber)/maps
```

质量默认 `auto`（按设备上报的 AVDTP 上限，通常是 400k），可把设备属性
`bluez5.a2dp.lhdc.quality` 设为 `400k` / `500k` / `900k` / `1000k`；不稳就退回 `auto`。

升级 `nixpkgs` 后先单独构建，别直接 switch：

```bash
nix build .#pipewire-lhdc
```

补丁是对着 1.6.9 生成的，上游相关文件一变就会在这里失败。若新版 PipeWire 已自带
`bluez5-codec-lhdc`，删掉 `pkgs/pipewire-lhdc` 与 `modules/hardware/audio-lhdc.nix`，
只保留 `liblhdcv5` 即可。

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
- [ ] 蓝牙耳机 `wpctl inspect <sink>` 显示 `api.bluez5.codec = "lhdc_v5"`
- [ ] fcitx5 输入法（Rime）可切换
- [ ] Steam 添加 `/mnt/steam/SteamLibrary` 后游戏可启动
- [ ] `kubectl get nodes` 为 Ready
- [ ] Windows 菜单项能进系统且显卡驱动正常（ACPI 注入生效）

## 回退

Arch 根子卷 `@`、包缓存 `@pkg`、日志 `@log` 及 Arch 期的根快照已于
2026-10-22 删除，**无法再回到 Arch**。删除前的残留配置留在：

- `/mnt/data/ARCH_MIGRATION_BACKUP_20261001/arch-etc-root-20261022.tar.zst`
  （Arch 的 `/etc` 与 `/root`）
- 同目录 `pacman-packages-20261022.txt`（1652 个包的名-版本清单）

现在的回退手段是 NixOS 自己的 generation：`nixos-rebuild --rollback switch`，
或开机时在 GRUB 里选上一个 generation。
