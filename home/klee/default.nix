# home-manager 用户配置
#
# 家目录与 Arch 共用，这里只做「新增」：装包、设环境变量。
# 不接管 Arch 已经在管理的文件（.config/fish、.config/nvim、KDE 配置等），
# 否则切回 Arch 时会看到一堆 .hm-bak。
{ pkgs, ... }:

{
  home.username = "klee";
  home.homeDirectory = "/home/klee";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    eza
    zoxide
    starship
    yazi
    lazygit
    tealdeer
    duf
    procs
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less";
  };
}
