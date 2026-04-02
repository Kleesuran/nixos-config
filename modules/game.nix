{ config, pkgs, ... }:

{
  # 1. 允许闭源软件 (建议放在这里，省去其他地方配置)
  nixpkgs.config.allowUnfree = true;

  # 2. Steam 配置 (这是一个独立的分支)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # 3. 硬件配置 (这是另一个独立的分支，注意它在 steam 的花括号外面)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
