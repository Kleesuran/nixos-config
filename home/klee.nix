{ config, pkgs, ... }:

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
    # DevOps Tools
    git curl wget kubectl kubernetes-helm k9s awscli2 google-cloud-sdk
    direnv vscode-fhs kitty terraform
    #user app
    localsend  google-chrome  qq opencode splayer
    # UI Components from ilyamiro
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true; 

}
