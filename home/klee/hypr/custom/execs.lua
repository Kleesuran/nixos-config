-- Custom execs for Hyprland
hl.on("hyprland.start", function ()
    -- kwalletd6 由 hyprland/execs.lua 启动；这里只补 Hyprland 会话缺少的组件
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP KDE_SESSION_VERSION PAM_KWALLET5_LOGIN")
    hl.exec_cmd("fcitx5 -d --replace")
    hl.exec_cmd("polkit-agent")
    hl.exec_cmd("hyprctl setcursor MaterialDesignLight 32")
end)
