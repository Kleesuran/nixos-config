{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.klee.daed;
  
  # 1. 正常模式：从 flake inputs 获取
  lockedDaedPackage = inputs.daeuniverse.packages.${pkgs.system}.daed;

  # 2. 方案 A: 零网络回退包
  # 你需要手动在配置目录下执行:
  # nix build .#nixosConfigurations.klee.config.services.daed.package -o .nix-cache/daed-bin
  # 并在断网死锁时启用 useFallback。
  fallbackPath = ../.nix-cache/daed-bin;
  fallbackExists = builtins.pathExists fallbackPath;

  fallbackPackage = if fallbackExists then
    pkgs.runCommand "daed-fallback" {} ''
      mkdir -p $out
      cp -r ${fallbackPath}/* $out/
    ''
  else
    pkgs.writeShellScriptBin "daed" "echo 'ERROR: Fallback binary not found at .nix-cache/daed-bin!' >&2; exit 1";

  # 决定最终使用哪个包
  finalPackage = if cfg.useFallback then fallbackPackage else lockedDaedPackage;

in
{
  # 我们已经在 modules/options.nix 中定义了选项，这里只需应用逻辑
  config = mkIf cfg.enable {
    services.daed = {
      enable = true;
      package = finalPackage;
    };

    # 自动开启防火墙端口
    networking.firewall.allowedTCPPorts = [ 2023 ];

    # 系统层面的提示，方便查看当前 daed 状态
    environment.etc."daed-status".text = if cfg.useFallback then "FALLBACK_MODE" else "NORMAL_MODE";
  };
}
