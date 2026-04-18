{ pkgs, lib, config, ... }:

{
  # Disable the daed service from daeuniverse module first
  services.daed.enable = lib.mkForce false;

  # Use your own overridden daed package with a systemd service
  systemd.services.daed = {
    description = "daed - eBPF-based high-performance transparent proxy";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = let
        daedFixed = pkgs.daed.overrideAttrs (old: {
          vendorHash = "sha256-b8fNqIrnfT5X3Pp4obbvryiwPX5sEYfWNO7G9ojW4TI=";
        });
      in "${daedFixed}/bin/daed run -c /etc/daed";
      Restart = "on-failure";
    };
  };

  # Create dummy config directory (adjust as needed)
  systemd.tmpfiles.rules = [
    "d /etc/daed 0755 root root -"
  ];

  # 开放 Web 控制面板端口 (默认 2023)
  networking.firewall.allowedTCPPorts = [ 2023 ];
}
