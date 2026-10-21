# 中文环境常用应用
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome
    chromium
    qq
    onlyoffice-desktopeditors
    obsidian
  ];
}
