{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # 优先使用清华大学二进制缓存镜像
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      
      # 优化网络超时设置，防止在网络抖动时安装中断
      connect-timeout = 5;
      builders-use-substitutes = true;
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

  # Docker
  virtualisation.docker.enable = true;

  # SSH
  services.openssh.enable = true;

  # Btrfs 定期优化
  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "weekly";

}
