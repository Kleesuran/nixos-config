{ pkgs, config, lib, ... }:

{
   home.packages = with pkgs; [
       swayosd
   ]; 

   services.swayosd = {
  	enable = true;
  	topMargin = 0.9;
        stylePath = "${config.home.homeDirectory}/.config/swayosd/style.css";
};

   xdg.configFile."swayosd/style.css".source = ./style.css;
}

