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
        fcitx5-gtk
        # fcitx5-mozc 当前在 nixpkgs 里编译失败（mozc 的 Qt UI 生成问题），
        # 需要日文输入时再单独用 overlay 修。
      ];
    };
  };
}
