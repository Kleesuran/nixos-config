# 开发工具
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 基础
    git
    gh
    curl
    wget
    ripgrep
    fd
    fzf
    jq
    yq
    tree
    unzip
    p7zip
    bat
    btop
    fastfetch

    # 编辑器 / 终端
    neovim
    tmux
    ghostty
    kitty

    # 语言运行时
    nodejs_22
    bun
    go
    rustup
    python3
    uv

    # 构建
    gcc
    gnumake
    cmake
    pkg-config

    # 容器 / K8s
    kubectl
    kubernetes-helm
    k9s
    ansible

    # 系统
    pciutils
    usbutils
    dmidecode
    lsof
    strace
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse
      icu
      openssl
      curl
      glib
      libxml2
      expat
      dbus
    ];
  };
}
