# NixOS Configuration - Klee Workstation

这是一个基于 Flake 的 NixOS 配置仓库，当前重点不是“堆功能”，而是把几个高风险区域拆干净：

- 图形驱动 / CUDA / Steam 运行时分层
- Fedora 第一层引导 + NixOS 第二层 generation 菜单
- daed 的锁定版本与离线缓存保底
- 针对 NTFS Steam 库的兼容处理

## 仓库结构

- [`flake.nix`](./flake.nix): 入口，定义 inputs 与 `nixosConfigurations.klee`
- [`hosts/`](./hosts): 主机级拼装
- [`home/`](./home): Home Manager 用户配置
- [`modules/`](./modules): 功能模块
- [`config/`](./config): 程序静态配置、脚本、主题资源
- [`.github/workflows/`](./.github/workflows): 云端构建与缓存导出

## 模块职责

- [`modules/system.nix`](./modules/system.nix): Nix 设置、系统基础包、Podman、防火墙、字体、本地缓存 substituter
- [`modules/boot.nix`](./modules/boot.nix): 通用启动参数、Plymouth、内核参数、文件系统支持
- [`modules/bootloader-grub.nix`](./modules/bootloader-grub.nix): NixOS 自己的 EFI/GRUB，引导逻辑与 `boot.nix` 解耦
- [`modules/graphics.nix`](./modules/graphics.nix): GPU 驱动与 32 位图形栈
- [`modules/cuda.nix`](./modules/cuda.nix): NVIDIA CUDA / container toolkit，仅负责计算栈
- [`modules/steam.nix`](./modules/steam.nix): Steam / Proton / Gamescope / GameMode / NTFS 修复脚本
- [`modules/klee-storage.nix`](./modules/klee-storage.nix): 当前机器的固定磁盘挂载
- [`modules/daed.nix`](./modules/daed.nix): daed 服务、锁定包选择、离线缓存导入导出脚本

## 当前关键设计

### 1. 图形、CUDA、Steam 已拆层

现在不是把所有游戏相关内容硬塞进 `steam.nix`。

- `graphics.nix` 负责显卡驱动与 32 位图形用户态
- `cuda.nix` 只负责 CUDA 与容器工具链
- `steam.nix` 只负责 Steam 运行时、GE-Proton、gamescope、gamemode、调试工具

对当前这台 NVIDIA Turing 机器，默认使用：

```nix
drivers.graphics = {
  enable = true;
  gpuType = "nvidia";
};

drivers.cuda.enable = true;
```

其中 NVIDIA 默认走更稳妥的专有内核模块路径，而不是强制 `open = true`。

### 2. Fedora 第一层引导，NixOS 第二层 rollback

引导逻辑现在已经解耦：

- Fedora GRUB 负责第一层启动菜单
- NixOS 仍保留自己的 EFI/GRUB，用来维护 generation 与 rollback

当前主机配置中：

```nix
bootloaders.nixosGrub = {
  enable = true;
  canTouchEfiVariables = false;
};
```

含义：

- NixOS 会继续生成自己的 GRUB 菜单
- 但不会去改 UEFI 启动顺序，不会和 Fedora 抢第一启动项
- Fedora 需要通过 chainload 进入 NixOS 的 EFI 启动项

### 3. Steam 库在 NTFS 上时，需要单独处理 compatdata

这份仓库默认承认一个现实：NTFS 上的 Steam 库可以“存游戏文件”，但 Proton 前缀直接放 NTFS 上并不稳，常见现象就是“游戏秒退”。

因此：

- [`modules/klee-storage.nix`](./modules/klee-storage.nix) 里只保留相对稳妥的 NTFS 挂载参数
- [`modules/steam.nix`](./modules/steam.nix) 提供了 `steam-fix-ntfs-library`

使用方式：

```bash
steam-fix-ntfs-library /run/media/klee/DATA-M.2/SteamLibrary
```

它会把该库下的 `steamapps/compatdata` 转成指向 Linux 文件系统的符号链接，避免 Proton 前缀直接写在 NTFS 上。

### 4. daed 默认锁定版本，支持本地缓存保底

`daed` 当前默认使用 `flake.lock` 锁定的 `daeuniverse` 包，不跟随“最新版漂移”：

```nix
profiles.daed.packagePreset = "locked";
```

如果之后你需要注入一个已知可用的旧版本包，可以改成：

```nix
profiles.daed.packagePreset = "custom";
profiles.daed.customPackage = myKnownGoodDaed;
```

这里的 `myKnownGoodDaed` 可以来自 overlay、本地 derivation，或者未来你自己补进来的旧版包定义。

更关键的是，这份配置现在支持本地二进制缓存保底：

- 本地缓存目录：`/run/media/klee/KIOXIA/Audiobooks/nixos/.nix-cache`
- `system.nix` 已将其加入 Nix substituters
- `daed.nix` 提供：
  - `seed-daed-cache`
  - `restore-daed-cache`

示例：

```bash
seed-daed-cache
restore-daed-cache /path/to/daed-cache.tar.gz
```

## GitHub Actions

### 1. NixOS CI

[`nixos-ci.yml`](./.github/workflows/nixos-ci.yml) 会执行：

- `nix flake check`
- `nix build .#nixosConfigurations.klee.config.system.build.toplevel`

用途是尽快发现模块求值错误和系统构建错误。

### 2. Daed Cache

[`daed-cache.yml`](./.github/workflows/daed-cache.yml) 会：

- 构建 `.#nixosConfigurations.klee.config.services.daed.package`
- 导出本地二进制缓存目录
- 上传 `daed-cache.tar.gz`、`daed-path.txt`、`daed-rev.txt`

用途是网络正常时提前把 daed 闭包烤出来，之后没梯子也能优先吃本地缓存。

## 常用操作

### 应用系统配置

```bash
sudo nixos-rebuild switch --flake .#klee
```

### 更新 flake 输入

```bash
nix flake update
```

### 预热 daed 本地缓存

```bash
seed-daed-cache
```

### 从 GitHub Actions 恢复 daed 缓存

```bash
restore-daed-cache ./daed-cache.tar.gz
```

### 修复 NTFS Steam 库的 Proton 前缀位置

```bash
steam-fix-ntfs-library /run/media/klee/DATA-M.2/SteamLibrary
```

## 迁移时要改的地方

更换机器时，优先检查：

- [`hosts/klee.nix`](./hosts/klee.nix) 里的 `drivers.graphics.gpuType`
- [`hosts/klee.nix`](./hosts/klee.nix) 里的 `drivers.cuda.enable`
- [`hosts/klee.nix`](./hosts/klee.nix) 里的 `bootloaders.nixosGrub`
- [`modules/klee-storage.nix`](./modules/klee-storage.nix) 里的 UUID 与挂载点
- [`hosts/klee-hardware.nix`](./hosts/klee-hardware.nix) 的自动生成硬件项

## 风险说明

- Fedora 第一层 GRUB 是否能显示 NixOS 入口，取决于 Fedora 侧是否正确 chainload 到 NixOS EFI 项
- NTFS Steam 库依然是“能用但不理想”的方案，尤其是 Proton 前缀和 shader cache
- daed 的“自定义旧版包”接口已经预留，但你仍需要自己提供那个旧包 derivation；目前真正可直接用的保底手段是本地缓存 artifact
