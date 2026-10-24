-- Fcitx5 Input Method environment variables
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")

-- Cursor Theme
hl.env("XCURSOR_THEME", "MaterialDesignLight")
hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_THEME", "MaterialDesignLight")
hl.env("HYPRCURSOR_SIZE", "32")

-- HDR & Vulkan WSI Environment Variables
hl.env("ENABLE_HDR_WSI", "1")
hl.env("DXVK_HDR", "1")

-- Keyring / Desktop Identity (Chromium & Electron auto-detect kwallet6)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland:KDE")
hl.env("KDE_SESSION_VERSION", "6")

