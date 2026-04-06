{ pkgs, config, lib, ... }:

{
  xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;
  xdg.configFile."hypr/hyprlock/scripts".source = ./scripts;
  xdg.configFile."hypr/hyprlock/colors.conf.template".source = ./colors.conf.template;

}
