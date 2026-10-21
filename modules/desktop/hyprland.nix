# Hyprland 作为可选会话，默认关闭；与 Plasma 并存
{ config, lib, pkgs, ... }:

let
  cfg = config.my.hyprland;
in
{
  options.my.hyprland.enable = lib.mkEnableOption "Hyprland 会话";

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    environment.systemPackages = with pkgs; [
      hyprpaper
      hypridle
      hyprlock
      wl-clipboard
      grim
      slurp
      fuzzel
    ];
  };
}
