{ config, pkgs, lib, ... }:

{ 
  xdg.configFile."matugen".source = ./.;
}
