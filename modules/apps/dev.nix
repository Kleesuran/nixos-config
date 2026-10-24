# 开发工具
{ pkgs, ... }:

{
  # 交互式 shell；用户登录 shell 仍是 bash（见 modules/core/users.nix）
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    # 基础
    git
    gh
    gh-dash
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
    qoder-cn
    workbuddy

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

    # 容器（podman 本体由 modules/services/podman.nix 提供）
    buildah
    skopeo
    dive
    hadolint
    nerdctl
    docker-compose

    # K8s
    kubectl
    kubernetes-helm
    k9s
    kustomize
    kubectx
    stern
    kubeseal
    kubeconform
    helmfile
    kube-linter
    k3d # 本地一次性集群；需要 user 级 podman.socket
    ansible

    # IaC
    opentofu # terraform 的 Apache 分支，功能等价
    terragrunt
    tflint
    terraform-docs
    terraform-ls

    # 配置管理
    ansible-lint
    molecule
    ansible-language-server

    # CI/CD
    act
    skaffold
    tilt
    gitlab-runner

    # 云 CLI
    awscli2
    # azure-cli 暂缺：它依赖 python3.14-fabric，当前 nixpkgs 里该包被标记 broken

    # 供应链安全 / Secret
    trivy
    syft
    grype
    cosign
    sops
    age
    # checkov 暂缺：依赖链里带 python3.14-ecdsa（被标记 insecure），用 trivy config 代替
    kube-bench
    kubeaudit
    popeye

    # GitOps / 备份
    argocd
    fluxcd
    velero

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
