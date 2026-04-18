{ pkgs, ... }:

let
  # 扁平化处理 Fcitx5 主题：直接将仓库中的主题文件夹拷贝到 share/fcitx5/themes
  candlelight-theme = pkgs.stdenv.mkDerivation {
    pname = "fcitx5-themes-candlelight";
    version = "master";
    src = pkgs.fetchFromGitHub {
      owner = "thep0y";
      repo = "fcitx5-themes-candlelight";
      rev = "master";
      hash = "sha256-dN77aUt1qkN177BZOfrT6O72Qp0J2jlM2mGNxI0cBnA=";
    };
    installPhase = ''
      mkdir -p $out/share/fcitx5/themes
      # 仓库内直接包含多个主题文件夹，我们将它们全部拷贝到目标路径
      cp -rv * $out/share/fcitx5/themes/
      # 移除不必要的文件，防止混淆 Fcitx5
      rm -f $out/share/fcitx5/themes/README.md
      rm -f $out/share/fcitx5/themes/LICENSE
      rm -rf $out/share/fcitx5/themes/screenshots
    '';
  };
in
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5.addons = with pkgs; [
      fcitx5-rime
      qt6Packages.fcitx5-chinese-addons
      qt6Packages.fcitx5-configtool
      # 将自定义的主题包加入 addons，NixOS 会自动将其 link 到全局 fcitx5 路径
      candlelight-theme
    ];
  };

  environment.sessionVariables = {
    # 在 Wayland 下，GTK/QT_IM_MODULE 已不再推荐手动指定，
    # 强制指定可能导致部分应用（如浏览器、电子应用）输入异常或崩溃。
    # 我们仅保留 XMODIFIERS 确保兼容 XWayland 软件。
    XMODIFIERS = "@im=fcitx";
  };
}
