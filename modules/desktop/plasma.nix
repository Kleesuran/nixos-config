# KDE Plasma 6（Wayland）
{ pkgs, ... }:

{
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

  programs.dconf.enable = true;

  services.upower.enable = true;
  services.fwupd.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.kwallet
    kdePackages.kwalletmanager
    kdePackages.kwallet-pam
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.kscreen
    kdePackages.discover
  ];

  security.pam.services.sddm.kwallet = {
    enable = true;
    package = pkgs.kdePackages.kwallet-pam;
  };
}
