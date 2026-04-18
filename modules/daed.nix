{ pkgs, ... }:

{
  # Override daed package with corrected vendorHash for goproxy.cn
  nixpkgs.overlays = [
    (final: prev: {
      daed = prev.daed.overrideAttrs (old: {
        vendorHash = "sha256-b8fNqIrnfT5X3Pp4obbvryiwPX5sEYfWNO7G9ojW4TI=";
      });
    })
  ];

  # 启用 daed 服务 (基于 eBPF 的高性能透明代理)
  services.daed = {
    enable = true;
  };

  # 开放 Web 控制面板端口 (默认 2023)
  networking.firewall.allowedTCPPorts = [ 2023 ];
}
