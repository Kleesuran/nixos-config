{ pkgs, config, lib, ... }:

let
  # 1. SDDM 主题: pixel-emerald
  pixel-emerald-sddm = pkgs.stdenv.mkDerivation {
    pname = "pixel-emerald-sddm";
    version = "1.0";
    src = ../config/themes/src/pixel-emerald.tar.gz;
    unpackPhase = "mkdir -p $out && tar -xzf $src -C $out";
    installPhase = "true"; # 已经在 unpackPhase 中处理
  };

  # 2. 全局主题 (Look and Feel): Catppuccin-Mocha-Blue
  catppuccin-plasma-theme = pkgs.stdenv.mkDerivation {
    pname = "catppuccin-plasma-theme";
    version = "1.0";
    src = ../config/themes/src/Catppuccin-Mocha-Blue.tar.gz;
    # 放置到标准 KDE 目录结构中
    installPhase = ''
      mkdir -p $out/share/plasma/look-and-feel
      cp -r . $out/share/plasma/look-and-feel/Catppuccin-Mocha-Blue
    '';
  };

  # 3. 图标主题: Tela-manjaro
  tela-manjaro-icons = pkgs.stdenv.mkDerivation {
    pname = "tela-manjaro-icons";
    version = "1.0";
    src = ../config/themes/src/Tela-manjaro.tar.gz;
    installPhase = ''
      mkdir -p $out/share/icons
      cp -r ./* $out/share/icons/
    '';
  };

in
{
  # 系统级安装：SDDM 与全局主题（为了 SDDM 预览和系统级默认值）
  environment.systemPackages = [
    catppuccin-plasma-theme
    tela-manjaro-icons
  ];

  # SDDM 设置
  services.displayManager.sddm = {
    theme = "pixel-emerald";
    extraPackages = [ pixel-emerald-sddm ];
  };

  # Home Manager 用户级配置
  home-manager.users.klee = {
    home.activation.applyPlasmaTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-lookandfeel -a Catppuccin-Mocha-Blue || true
    '';
    
    # 图标主题在 home.nix 中已经有部分逻辑，但我们这里显式指定
    gtk.iconTheme = {
      name = "Tela-manjaro-dark";
      package = tela-manjaro-icons;
    };
  };
}
