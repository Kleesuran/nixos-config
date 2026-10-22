# 从旧 Arch/AUR 环境迁移过来的应用
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    darkly
    ghidra
    localsend
    papirus-folders
    papirus-icon-theme
    polychromatic
    qdiskinfo
    splayer-next
    zedg
  ];

  hardware.openrazer.enable = true;
  hardware.openrazer.users = [ "klee" ];
  hardware.openrazer.packages.kernel = config.boot.kernelPackages.openrazer.overrideAttrs (old: {
    # The modules aggregator concatenates <module>.ko.cer for every external
    # module, but OpenRazer installs unsigned modules without those sidecars.
    postInstall = ''
      for module in $out/lib/modules/*/kernel/drivers/hid/*.ko; do
        touch "$module.cer"
      done
    '';
  });
  programs.openlogi.enable = true;

  programs.ydotool.enable = true;
  users.users.klee.extraGroups = [ "ydotool" ];
}
