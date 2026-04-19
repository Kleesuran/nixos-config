{ config, lib, ... }:

with lib;
let
  cfg = config.bootloaders.nixosGrub;
in
{
  options.bootloaders.nixosGrub = {
    enable = mkEnableOption "NixOS-managed GRUB/EFI bootloader";

    efiSysMountPoint = mkOption {
      type = types.str;
      default = "/boot";
      description = "EFI system partition mount point used by the NixOS GRUB installation.";
    };

    canTouchEfiVariables = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether NixOS may update UEFI boot variables. Keep this disabled when
        Fedora should remain the first-stage boot manager and only chainload
        into NixOS.
      '';
    };

    useOSProber = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to use OS Prober to find other OSs.";
    };
  };

  config = mkIf cfg.enable {
    boot.loader = {
      efi = {
        canTouchEfiVariables = cfg.canTouchEfiVariables;
        efiSysMountPoint = cfg.efiSysMountPoint;
      };

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = cfg.useOSProber;
        gfxmodeEfi = "auto";
        configurationLimit = 10;
      };
    };
  };
}
