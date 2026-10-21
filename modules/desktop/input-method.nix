# 中文输入法：fcitx5 + Rime
{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-rime
        fcitx5-mozc
        fcitx5-gtk
      ];
    };
  };
}
