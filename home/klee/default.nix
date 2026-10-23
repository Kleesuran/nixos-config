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
    aliyun-cli
    antigravity-cli
    codebuddy
    codex
    google-cloud-sdk
    grok-build
    nfpm
    opencode
    qoder-cli
    rea-agents
    (writeShellApplication {
      name = "mihomo-try";
      runtimeInputs = [
        mihomo
        curl
        coreutils
        gnused
        gnugrep
        systemd
      ];
      text = builtins.readFile ./scripts/mihomo-try.sh;
    })
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less";
  };

  # KDE 自带 org.kde.plasma.bluetooth 托盘图标已经够用；
  # 屏蔽 Blueman 的重复图标，但保留 blueman 包，blueman-manager 仍可手动启动。
  xdg.configFile = {
    "autostart/blueman.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Blueman Applet
      Hidden=true
    '';

    # fish 只接管 config.fish；conf.d/、completions/、fish_variables 属于运行时状态
    "fish/config.fish".source = ./fish/config.fish;
    "git/ignore".source = ./git/ignore;

    # 手工编辑的只读配置。btop 若在界面里改设置会尝试回写，需改为改仓库；
    # kitty/ghostty 只读配置，状态在 ~/.local/state。
    "starship.toml".source = ./starship/starship.toml;
    "starship_kde.toml".source = ./starship/starship_kde.toml;
    "kitty".source = ./kitty;
    "ghostty".source = ./ghostty;
    # 只接管 init.lua，nvim-pack-lock.json 由 vim.pack 自行维护
    "nvim/init.lua".source = ./nvim/init.lua;
    "btop/btop.conf".source = ./btop/btop.conf;

    # systemd 262 对 Type=notify-reload 会检查主进程的 SIGUSR2 handler，
    # Ghostty 1.3.1 在装好 handler 之前就发了 READY=1，D-Bus 激活时约一半概率被判
    # "lacks handler for reload signal USR2" 而拒绝启动（ghostty#14398）。
    # 上游 1.4.0 才修，这里降成 notify 绕过；改配置仍用 super+shift+r。
    "systemd/user/app-com.mitchellh.ghostty.service.d/10-no-notify-reload.conf".text = ''
      [Service]
      Type=notify
    '';
  };

  # git 的全局配置（用户名/邮箱/凭据助手）。SSH 私钥和任何 token 都不进仓库。
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Kleesuran";
        email = "attnia@outlook.com";
      };
      init.defaultBranch = "main";
      core.editor = "nvim";
      # 空值先清掉继承来的 helper 列表，再挂 gh
      credential."https://github.com".helper = [ "" "!${pkgs.gh}/bin/gh auth git-credential" ];
      credential."https://gist.github.com".helper = [ "" "!${pkgs.gh}/bin/gh auth git-credential" ];
    };
  };

  # Rime 只托管「只读输入」：全局补丁与自定义短语。
  # build/、userdb/、user.yaml、installation.yaml、sync/ 都是运行时状态，不接管，
  # 否则 Rime 写入时会撞上只读的 store 软链。
  xdg.dataFile = {
    "fcitx5/rime/default.custom.yaml".source = ./rime/default.custom.yaml;
    "fcitx5/rime/custom_phrase.txt".source = ./rime/custom_phrase.txt;
  };

  systemd.user.services.protonplus = {
    Unit.Description = "ProtonPlus runner update";
    Service = {
      # Type=simple：启动立即返回，避免 HM 激活（sd-switch 重启该单元）
      # 傻等整个 runner 更新流程而超时。
      ExecStart = "${pkgs.protonplus}/bin/protonplus update all";
      RuntimeMaxSec = "2h";
    };
  };

  systemd.user.timers.protonplus = {
    Unit.Description = "Hourly ProtonPlus runner update";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
