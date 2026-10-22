# WorkBuddy CN

## 当前版本

- Nix `version`：`5.6.2.40046327_c7b525f3`
- deb control `Version`：`5.6.2`
- 来源（版本化地址，URL 里的版本用 `-`）：
  `https://download.codebuddy.cn/workbuddy/saas/linux-x64-deb/WorkBuddy-linux-x64-deb-5.6.2.40046327-c7b525f3.deb`
- 当前 hash：`sha256-EhSa2MDNdI/VBi2PYseCfWiNgJVCetqZsa6ecBmJdSM=`
- 安装后命令：`/run/current-system/sw/bin/workbuddy`
- 桌面项：`/run/current-system/sw/share/applications/workbuddy.desktop`
  （来自 AUR 的 `WorkBuddy.desktop`，带 agentmail / discover / my-files / settings / skills 动作）

## 更新步骤

1. 从 AUR `workbuddy` 的 PKGBUILD / `.SRCINFO` 或 CodeBuddy 官方下载页取得新版 deb。

2. 查看新 deb 的版本：

   ```bash
   ar p WorkBuddy-linux-x64-deb-<version>.deb control.tar.xz \
     | tar xO ./control | grep '^Version:'
   ```

3. 计算 Nix 需要的 SHA-256（SRI）：

   ```bash
   nix hash file --type sha256 --sri WorkBuddy-linux-x64-deb-<version>.deb
   ```

4. 修改本目录 `default.nix`：

   ```nix
   version = "5.6.2.40046327_c7b525f3";   # Nix 版本用 '_'
   hash = "sha256-...";                    # 用上一步的结果
   ```

   源码 URL 会自动把 `version` 里的 `_` 换成 `-`（`lib.replaceStrings`），
   不需要手动改 URL。

5. 重新构建并切换：

   ```bash
   pkexec nixos-rebuild switch --flake /mnt/repos/nixos-config#legion-t5
   ```

6. 验证：

   ```bash
   /run/current-system/sw/bin/workbuddy
   ```

   另外确认捆绑运行时：

   ```bash
   P=$(dirname "$(readlink -f /run/current-system/sw/bin/workbuddy)")/..
   "$P/opt/WorkBuddy/resources/runtime/node/bin/node" -v   # 应打印系统 Node 22.x
   "$P/opt/WorkBuddy/resources/runtime/python/bin/python3" -V
   ```

## 注意

- 这是完整 Electron 包，安装后约 1.7 GB（自带 Python 3.13 和 Node 运行时）。
  不要用应用内置更新器，升级必须走本包。
- 打包时必须清理非 Linux-x64 的可选原生模块，否则 `autoPatchelf` 会尝试解析
  OpenBSD/macOS/Windows/arm64 的二进制而失败。当前清理规则：
  - 删除所有名字含 `musl` 的目录
  - `koffi/build/koffi/*` 只保留 `linux_x64`
  - `@lydell/node-pty-*` 只保留 `node-pty-linux-x64`
  - 删除 `fsevents`
  新版本如果引入新的平台目录，按报错补进 `postInstall` 的清理列表。
- 上游 bundled Node（`resources/runtime/node/bin/node`）被 patchelf 后启动会
  段错误；`postInstall` 已把它替换成调用 `pkgs.nodejs_22` 的 shell wrapper。
  如果新版本调整了运行时路径，需要同步修改 `node_bin` 那段。
- 桌面项来自 AUR 的 `WorkBuddy.desktop`；如果上游/AUR 更新了动作或
  `StartupWMClass`，同步更新本目录的 `WorkBuddy.desktop`。
- 应用不会自己写用户级 desktop 文件，KDE 菜单直接使用系统 profile 里的 desktop。
- 需要 `nixpkgs.config.allowUnfree = true`（已在 `modules/core/nix.nix` 设置）。
