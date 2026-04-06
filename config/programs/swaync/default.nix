{ pkgs, config, lib, ... }:

{
   home.packages = with pkgs; [
       pkgs.swaynotificationcenter
   ];

   xdg.configFile."swaync".source = ./.;
}
