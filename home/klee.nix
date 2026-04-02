{ config, pkgs, nvim-config, ... }:

let
  # 程序的相对路径，注意在 Flake 结构中，home 目录位于 ./home/，而 config 位于 ./config/
  # 因此从 ./home/klee.nix 引用 config 应该用 ../config/
  programsDir = ../config/programs;
  files = builtins.readDir programsDir;
  directories = builtins.filter 
    (name: files.${name} == "directory") 
    (builtins.attrNames files);
  programImports = map (name: programsDir + "/${name}") directories;
in
{
  imports = [
    ../config/sessions/hyprland/default.nix
  ] ++ programImports; 

  home.username = "klee";
  home.homeDirectory = "/home/klee";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # --- DevOps & Infrastructure ---
    opentofu                # Terraform 的开源替代品，网速更快更友好
    ansible                 # 配置管理必备
    kubectl kubernetes-helm k9s
    awscli2 google-cloud-sdk
    
    # --- Containers ---
    podman-compose          # 多容器编排学习
    
    # --- Automation & Data ---
    jq yq-go                # JSON/YAML 处理专家
    gh                      # GitHub 命令行工具
    python3Full             # 运维脚本核心
    
    # --- Development & DX ---
    git curl wget direnv
    go                      # Go 语言环境
    vscode-fhs kitty
    
    # --- Networking & Debug ---
    bind.dnsutils           # dig, nslookup
    mtr                     # 更好的 traceroute
    nmap                    # 端口扫描与审计
    
    # --- User Apps ---
    localsend google-chrome qq opencode splayer
    
    # --- UI Components ---
    adwaita-icon-theme adw-gtk3 jetbrains-mono nerd-fonts.jetbrains-mono
    inter noto-fonts-cjk-sans bibata-cursors papirus-icon-theme
  ];
    
  # ilyamiro Style Cursor
  home.pointerCursor = 
  let 
    getFrom = url: hash: name: {
        gtk.enable = true;
        x11.enable = true;
        name = name;
        size = 24;
        package = 
          pkgs.runCommand "moveUp" {} ''
            mkdir -p $out/share/icons
            ln -s ${pkgs.fetchzip {
              url = url;
              hash = hash;
            }}/dist $out/share/icons/${name}
          '';
      };
  in
    getFrom 
      "https://github.com/yeyushengfan258/ArcMidnight-Cursors/archive/refs/heads/main.zip"
      "sha256-VgOpt0rukW0+rSkLFoF9O0xO/qgwieAchAev1vjaqPE=" 
      "ArcMidnight-Cursors";

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-theme-name = "adw-gtk3-dark";
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
  };

  xdg.configFile."nvim" = {
    source = nvim-config;
    recursive = true;
  };

  home.file = {
    ".local/share/fonts/" = {
      source = ../config/fonts; 
      recursive = true;
    };
    ".config/hypr/scripts/" = {
      source = ../config/sessions/hyprland/scripts;
      recursive = true;
    };
  };

  services.easyeffects.enable = true;  

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # 别名映射：将 terraform 指向 tofu，将 docker 映射到 podman (通过 zsh 确保交互式体验)
  programs.zsh = {
    enable = true;
    shellAliases = {
      # IaC 转换
      terraform = "tofu";
      tf = "tofu";
      # 容器转换 (虽然系统已经有兼容，但 Zsh 别名能让 tab 补全更顺畅)
      docker = "podman";
      "docker-compose" = "podman-compose";
      # Go 常用
      gmod = "go mod tidy";
      gr = "go run";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # 设置 Go 语言相关的环境变量，特别是在国内开发需要代理
  home.sessionVariables = {
    GOPROXY = "https://goproxy.cn,direct";
    GOSUMDB = "sum.golang.google.cn";
  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true; 

}
