{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # 优先使用国内二级缓存镜像
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirror.sjtu.edu.cn/nixos" # 上海交大镜像
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      
      # 容忍国内弱网抖动，增加超时时间
      connect-timeout = 30;
      builders-use-substitutes = true;
      # 开启并发下载
      max-jobs = "auto";
    };
    
    # 将系统中的 nixpkgs 注册表也指向镜像，提升日常 nix 命令速度
    registry.nixpkgs.to = {
      type = "path";
      path = pkgs.path;
    };
  };

  environment.systemPackages = with pkgs; [
    git vim curl wget htop btop neovim 
  ];

  # ZSH 必须在系统级启用才能作为默认 shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # 区域与语言设置 (简体中文)
  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.supportedLocales = [ "zh_CN.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # Podman (作为 Docker 的更佳替代方案)
  virtualisation.podman = {
    enable = true;
    # 启用 Docker 别名，学习时可以使用 docker 命令调用 podman
    dockerCompat = true;
    # 默认网络设置
    defaultNetwork.settings.dns_enabled = true;
  };

  # SSH
  services.openssh.enable = true;

  # CUPS 打印支持 (含网络发现)
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Flatpak 支持
  services.flatpak.enable = true;

  # Btrfs 定期优化
  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "weekly";

}
