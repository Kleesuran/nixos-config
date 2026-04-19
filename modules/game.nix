{ config, pkgs, ... }:

{
  # 1. 允许闭源软件 (建议放在这里，省去其他地方配置)
  nixpkgs.config.allowUnfree = true;

  # Steam 已经移至单独的 modules/steam.nix 进行高级配置
}
