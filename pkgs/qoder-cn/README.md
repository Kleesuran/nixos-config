# Qoder CN

## 当前版本

- Nix `version`：`0.4.8`
- deb control `Version`：`1:0.4.8`
- 来源（官方下载页实际使用的 latest 地址）：
  `https://qoder-app.oss-cn-beijing.aliyuncs.com/qoder-app/releases/latest/Qoder-CN-linux-amd64.deb`
- 当前 hash：`sha256-haHVJ0P1bxblGLEoX7jdYtvqXP2u82Im1Jbtkv7nN8Y=`
- 安装后命令：`/run/current-system/sw/bin/qoder-cn`
- 桌面项：`/run/current-system/sw/share/applications/qoder-cn.desktop`

## 更新步骤

1. 从官方下载页取得新的 Linux deb（或直接下载上面的 latest 地址）。

2. 查看新 deb 的版本：

   ```bash
   ar p Qoder-CN-linux-amd64.deb control.tar.xz \
     | tar xO ./control | grep '^Version:'
   ```

3. 计算 Nix 需要的 SHA-256（SRI）：

   ```bash
   nix hash file --type sha256 --sri Qoder-CN-linux-amd64.deb
   ```

4. 修改本目录 `default.nix`：

   ```nix
   version = "0.4.8";                 # 改成新版本
   hash = "sha256-...";               # 用上一步的结果
   ```

5. 重新构建并切换：

   ```bash
   pkexec nixos-rebuild switch --flake /mnt/repos/nixos-config#legion-t5
   ```

6. 验证：

   ```bash
   /run/current-system/sw/bin/qoder-cn
   ```

   应用启动后确认登录、界面和 Windows/KDE 集成正常。

## 注意

- 源码地址用的是 `latest`，上游一发版，固定 hash 就会对不上；这是故意的，
  避免在不知情的情况下换版本。更新时重新下载并替换 hash 即可。
- 不要用应用内置的更新器；它不能替换 Nix store 里的二进制，升级必须走本包。
- 应用启动时会自己重写 `~/.local/share/applications/qoder-cn.desktop`，把
  `Exec` 指向当前 Nix store 路径。升级后建议先删掉这个用户级文件，再启动一次，
  否则 KDE 菜单可能仍指向旧 store 路径：

  ```bash
  rm -f ~/.local/share/applications/qoder-cn.desktop
  /run/current-system/sw/bin/qoder-cn
  ```

- 打包时会删除 `@img/sharp-*-musl*` 等 musl 可选模块，避免 `autoPatchelf`
  去找 musl libc；新版本如果新增平台目录，先看 `nixos-rebuild` 的报错再补清理。
- Qoder 的命令行工具是另一套（`~/.qoder-cn/bin/qoderclicn`，`~/.local/bin/qoder`
  指向它），不由这个包管理。
- 需要 `nixpkgs.config.allowUnfree = true`（已在 `modules/core/nix.nix` 设置）。
