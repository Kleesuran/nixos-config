{ config, pkgs, nvim-config, ilyamiro-config, ... }:

let
  # 这里的 programImports 逻辑可以保留，用于加载本地定义
  programsDir = ../config/programs;
  files = builtins.readDir programsDir;
  directories = builtins.filter 
    (name: files.${name} == "directory") 
    (builtins.attrNames files);
  programImports = map (name: programsDir + "/${name}") directories;
in
{
  imports = [
    # 核心：直接引用 ilyamiro 的桌面环境配置作为基础，实现自动同步
    (ilyamiro-config + "/config/sessions/hyprland/default.nix")
  ] ++ programImports; 

  home.username = "klee";
  home.homeDirectory = "/home/klee";
  home.stateVersion = "24.11";

  # ilyamiro's Rice 核心组件引用
  # 我们直接将远程仓库的 config 映射到本地，确保配置是最新的且完整的
  xdg.configFile = {
    "matugen".source = ilyamiro-config + "/config/programs/matugen";
    "swaync".source = ilyamiro-config + "/config/programs/swaync";
    "swayosd".source = ilyamiro-config + "/config/programs/swayosd";
    "waybar".source = ilyamiro-config + "/config/programs/waybar";
    "cava".source = ilyamiro-config + "/config/programs/cava";
    "rofi".source = ilyamiro-config + "/config/programs/rofi";
    "kitty".source = ilyamiro-config + "/config/programs/kitty";
  };

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
    python3                 # 运维脚本核心 (已从 python3Full 更名)
    
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
    
    # --- UI Components from ilyamiro ---
    adwaita-icon-theme adw-gtk3 jetbrains-mono nerd-fonts.jetbrains-mono
    inter noto-fonts-cjk-sans bibata-cursors papirus-icon-theme
    
    # --- Missing Dependencies for ilyamiro's Rice ---
    ffmpeg                  # qs_manager.sh 缩略图生成
    bc                      # 脚本计算
    socat                   # 脚本通信
    brightnessctl           # 亮度控制
    pamixer                 # 音量控制
    playerctl               # 媒体控制
    swww                    # 壁纸引擎
    imagemagick             # 图像处理
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
    gtk4.theme = null; # 消除 Home Manager 24.11+ 的警告
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
      source = ilyamiro-config + "/config/fonts"; 
      recursive = true;
    };
    ".config/hypr/scripts/" = {
      source = ilyamiro-config + "/config/sessions/hyprland/scripts";
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
    NIXOS_OZONE_WL = "1";
  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true; 

}
