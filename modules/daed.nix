{ pkgs, ... }:

{
  services.daed = {
    enable = true;
    package = pkgs.daed.overrideAttrs (old: {
      vendorHash = "sha256-88ARxRy9u4mF/yllqJmaim6v+vPHOMGu3/MYoDPO0dQ=";
    });
  };

  networking.firewall.allowedTCPPorts = [ 2023 ];
}
