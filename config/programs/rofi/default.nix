{ config, lib, ... }:

{ 
  xdg.configFile."rofi".source = ./.;
}
