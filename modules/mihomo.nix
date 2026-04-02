{ config, pkgs, ... }:

{
  # 1. 确保内核开启了 TUN 模块
  boot.kernelModules = [ "tun" ];

  # 2. 极其重要：开启 nix-ld
  # 许多预编译的 App (如 FlClash) 需要动态链接库，NixOS 默认不提供标准路径。
  # 开启这个可以解决大部分二进制文件“无法运行”或“找不到文件”的问题。
  programs.nix-ld.enable = true;

  # 3. 如果你使用 TUN 模式，通常需要关闭反向路径过滤
  # 否则系统会认为代理流量是“欺骗”流量而丢弃
  networking.firewall.checkReversePath = false;

  # 4. 允许普通用户组使用 TUN 设备 (可选)
  # 某些情况下需要将你的用户名加入相关组，但通常 nix-ld + 下面的方法更有效
}
