{ config, lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-2, 1920x1080@165, 0x0, 1.0"
      ", preferred, auto, 1"
    ];
  }; 
}
