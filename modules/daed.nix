{ pkgs, inputs, ... }:

{
  services.daed = {
    enable = true;
    # 强制指定使用 daeuniverse Flake 提供的 package
    # 这样可以绕过本地 go 构建可能遇到的 vendorHash 校验问题
    package = inputs.daeuniverse.packages.${pkgs.system}.daed;
  };

  networking.firewall.allowedTCPPorts = [ 2023 ];
}
