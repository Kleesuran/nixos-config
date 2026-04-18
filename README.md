# NixOS Configuration - Klee DevOps Workstation

这是一个高度模块化的 NixOS Flake 配置，专门为 DevOps 学习、开发、AI 实验以及日常多媒体需求设计。

## 📁 仓库结构说明 (Project Structure)

本仓库采用清晰的职责分离设计，方便维护和迁移：

- **`flake.nix`**: 整个系统的入口文件，管理所有外部依赖（Inputs）和主机定义（Outputs）。
- **`hosts/`**: 存放主机特定的 NixOS 系统级配置。
    - `klee.nix`: 主机 `klee` 的主要配置文件，负责导入模块和开关功能。
    - `klee-hardware.nix`: 自动生成的硬件扫描配置文件（包含文件系统挂载、内核模块等）。
- **`home/`**: 存放 Home Manager 用户级配置。
    - `klee.nix`: 定义用户 `klee` 的软件包、环境变量、Shell 别名及点文件关联。
- **`modules/`**: 核心功能模块，按功能解耦。
    - `graphics.nix`: 统一显卡驱动管理（支持 NVIDIA/AMD/Intel）。
    - `cuda.nix`: NVIDIA CUDA 容器加速支持。
    - `klee-storage.nix`: 针对特定设备的 NTFS 硬盘挂载策略。
    - `daed.nix`: 基于 eBPF 的高性能透明代理。
    - `devops-lab.nix`: 手动开关的实验端口防火墙服务。
    - `system.nix` / `boot.nix` / `input.nix` / `game.nix` 等：系统基础服务、引导、输入法及游戏环境。
- **`config/`**: 存放静态配置文件、脚本或主题模板。

---

## 🚀 核心硬件配置 (必读)

为了方便未来迁移到新电脑，本配置将硬件相关的设置封装成了开关。当你更换硬件时，请修改 `hosts/klee.nix` 中的以下选项：

### 1. 显卡驱动与 CUDA (`drivers.graphics` & `cuda`)
用于自动加载驱动、硬件视频加速包及容器 GPU 支持。
- **配置项**:
  ```nix
  drivers.graphics = {
    enable = true;          # 启用图形支持
    gpuType = "nvidia";     # 可选值: "nvidia", "amd", "intel", "none"
  };

  drivers.cuda.enable = true; # 启用 CUDA (仅在 gpuType="nvidia" 时生效)
  ```
- **注意**: 启用 `cuda.enable` 后，Podman/Docker 容器将具备 NVIDIA Container Toolkit (CDI) 支持，可直接调用 GPU。

### 2. 特定设备挂载 (`device.klee-2070m`)
这是针对当前特定设备（RTX 2070 Mobile）的 NTFS 硬盘挂载。
- **配置项**:
  ```nix
  device.klee-2070m.enable = true;
  ```
- **注意**: 
  - 该模块包含了硬编码的磁盘 UUID。**更换电脑后请将其设为 `false`**。
  - 挂载路径统一为 Plasma 风格的 `/run/media/klee/`。

---

## 🛠️ 运维与开发功能

### DevOps 实验模式 (端口开关)
手动开启实验环境端口（3000-3010, 8080, 5432 等）：
- **开启**: `sudo systemctl start devops-ports`
- **关闭**: `sudo systemctl stop devops-ports`
- **特性**: 默认不启动且禁止 enable，重启后自动关闭，保证系统安全。

### 透明代理 (`daed`)
- 默认监听 **2023** 端口。
- **控制面板**: [http://localhost:2023](http://localhost:2023)

---

## 📦 如何应用更改

1. **应用系统配置**:
   ```bash
   sudo nixos-rebuild switch --flake .#klee
   ```
2. **更新外部输入 (Inputs)**:
   ```bash
   nix flake update
   ```
   *注意：Neovim 配置已切换为 SSH 协议，请确保本地已配置 GitHub SSH Key。*
