# end4-pC（illogical-impulse 分支）桌面环境
#
# ~/.config/hypr、matugen、fuzzel、Kvantum 必须可写：end4 设置面板和
# switchwall.sh 会在运行中改写这些目录。其余 quickshell 源码保持只读 store。
{ config, lib, osConfig, pkgs, inputs, ... }:

let
  cfg = osConfig.my.hyprland;

  end4Pc = pkgs.applyPatches {
    name = "end4-pC-patched";
    src = inputs.end4-pC;
    patches = [
      ../../pkgs/end4-pC/patches/0001-local-tweaks.patch
      ../../pkgs/end4-pC/patches/0002-config-name.patch
    ];
  };

  # 这些目录会被 matugen / switchwall / Kvantum 运行时写入。
  writableConfig = name: config.lib.file.mkOutOfStoreSymlink
    "/mnt/repos/nixos-config/home/klee/${name}";

  # nixpkgs 的 quickshell 只带 qtbase/qtdeclarative/qtwayland/qtsvg；
  # end4-pC 还 import 了 Qt5Compat、QtPositioning、QtMultimedia 等 QML 模块。
  qmlImportPath = lib.makeSearchPath "lib/qt-6/qml" [
    pkgs.qt6.qt5compat
    pkgs.qt6.qtpositioning
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qtvirtualkeyboard
    pkgs.qt6.qtquicktimeline
    pkgs.qt6.qtsensors
    pkgs.qt6.qtlocation
    pkgs.kdePackages.kirigami.unwrapped
    pkgs.kdePackages.syntax-highlighting
  ];

  qmlPluginPath = lib.makeSearchPath "lib/qt-6/plugins" [
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qtvirtualkeyboard
  ];

  quickshell = pkgs.runCommand "quickshell-end4" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir -p $out/bin
    for bin in qs quickshell; do
      makeWrapper ${pkgs.quickshell}/bin/$bin $out/bin/$bin \
        --prefix QML2_IMPORT_PATH : "${qmlImportPath}" \
        --prefix QT_PLUGIN_PATH : "${qmlPluginPath}"
    done
  '';

  # 把 Arch 时期用的 MaterialDesignLight 光标主题固化进 Nix store
  materialDesignLight = pkgs.runCommand "material-design-light-cursors" { } ''
    mkdir -p $out/share/icons
    cp -a ${./icons/MaterialDesignLight} $out/share/icons/MaterialDesignLight
  '';

  # polkit 认证代理：Hyprland 用官方的 hyprpolkitagent，KDE 会话用 KDE 的代理。
  # 只在 Hyprland 的 execs.lua 里启动；Plasma 自己会启动 KDE 代理。
  polkitAgent = pkgs.writeShellScriptBin "polkit-agent" ''
    case "$XDG_CURRENT_DESKTOP" in
      *Hyprland*)
        exec ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent "$@"
        ;;
      *KDE*|*Plasma*)
        exec ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1 "$@"
        ;;
      *)
        exec ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent "$@"
        ;;
    esac
  '';

  # 与 dots-hyprland sdata/uv/requirements.txt 对齐；用 Nix 构建，避免
  # Arch 的 uv venv 在 NixOS 上缺 libffi/libGL。
  pythonEnv = pkgs.python312.withPackages (ps: with ps; [
    pillow
    numpy
    opencv4
    pygobject3
    pycairo
    psutil
    requests
    google-auth
    click
    loguru
    tqdm
    setproctitle
    materialyoucolor
    libsass
    pywayland
    kde-material-you-colors
    material-color-utilities
    setuptools
    setuptools-scm
    wheel
    build
  ]);

  # 让脚本继续 source "$ILLOGICAL_IMPULSE_VIRTUAL_ENV/bin/activate"，
  # 但实际 python 来自 Nix store。
  quickshellVenv = pkgs.runCommand "quickshell-venv" { } ''
    mkdir -p $out/bin
    ln -s ${pythonEnv}/bin/python3 $out/bin/python
    ln -s ${pythonEnv}/bin/python3 $out/bin/python3
    cat > $out/bin/activate <<'EOF'
    export VIRTUAL_ENV=${placeholder "out"}
    export PATH=${placeholder "out"}/bin:${pythonEnv}/bin:$PATH
    export GI_TYPELIB_PATH=${lib.makeSearchPath "lib/girepository-1.0" [
      pkgs.gtk4
      pkgs.gdk-pixbuf
      pkgs.gnome-desktop
      pkgs.gsettings-desktop-schemas
      pkgs.libadwaita
      pkgs.libsoup_3
      pkgs.libportal-gtk4
    ]}
    deactivate() { :; }
    EOF
  '';
in
lib.mkIf cfg.enable {
  xdg.configFile = {
    # end4 设置面板会写 shellOverrides/main.lua、hyprlock.conf、monitors.lua 等
    "hypr".source = config.lib.file.mkOutOfStoreSymlink
      "/mnt/repos/nixos-config/home/klee/hypr";

    "quickshell/end4-pC".source = end4Pc;

    "matugen".source = writableConfig "matugen";
    "fuzzel".source = writableConfig "fuzzel";
    "Kvantum".source = writableConfig "Kvantum";

    "foot".source = "${inputs.dots-hyprland}/dots/.config/foot";
    "wlogout".source = "${inputs.dots-hyprland}/dots/.config/wlogout";
  };

  # Hyprland 的 env.lua 指向 ~/.local/state/quickshell/.venv
  home.file.".local/state/quickshell/.venv".source = quickshellVenv;

  home.packages = with pkgs; [
    # Hyprland 生态
    hypridle
    hyprlock
    hyprpicker
    hyprsunset
    hyprshot

    # 截图 / 录屏 / 剪贴板 / 启动器
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    wf-recorder
    tesseract
    fuzzel
    wtype
    playerctl
    lxqt.pavucontrol-qt
    cava
    brightnessctl
    ddcutil

    # 壁纸 / 取色 / 主题
    matugen
    imagemagick
    mpvpaper
    ffmpeg
    libqalculate
    translate-shell
    songrec
    wlogout
    adw-gtk3
    darkly
    kdePackages.breeze
    material-cursors

    # 运行时小工具
    bc
    psmisc
    libnotify
    glib
    gsettings-desktop-schemas
    gnome-keyring
    easyeffects
    xdg-user-dirs
    xdg-utils

    # KDE 组件（Hyprland 会话里手动拉起）
    kdePackages.bluedevil
    kdePackages.plasma-nm
    kdePackages.dolphin
    kdePackages.systemsettings
    kdePackages.polkit-kde-agent-1
    hyprpolkitagent
    polkitAgent

    quickshell
  ];

  home.pointerCursor = {
    enable = true;
    name = "MaterialDesignLight";
    package = materialDesignLight;
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };

  # Plasma 的 kcminputrc 不属于 home.pointerCursor 管理范围
  home.activation.setKdeCursor = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} --file kcminputrc --group Mouse --key cursorTheme MaterialDesignLight
    ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} --file kcminputrc --group Mouse --key cursorSize 32
  '';

  home.sessionVariables = {
    ILLOGICAL_IMPULSE_VIRTUAL_ENV =
      "${config.home.homeDirectory}/.local/state/quickshell/.venv";
  };
}
