{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.drivers.graphics;
  isNvidia = cfg.gpuType == "nvidia";
  isAmd = cfg.gpuType == "amd";
  isIntel = cfg.gpuType == "intel";
in
{
  options.drivers.graphics = {
    enable = mkEnableOption "system graphics stack";
    gpuType = mkOption {
      type = types.enum [ "nvidia" "amd" "intel" "none" ];
      default = "none";
      description = "Which GPU driver family should be configured.";
    };
  };

  config = mkIf cfg.enable {
    # Steam/Proton and many native games still need 32-bit userspace.
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages =
        with pkgs;
        [ libva-vdpau-driver libvdpau-va-gl ]
        ++ optionals isIntel [ intel-media-driver vaapiIntel ]
        ++ optionals isAmd [ libvdpau vaapiVdpau ]
        ++ optionals isNvidia [ nvidia-vaapi-driver ];
      extraPackages32 =
        with pkgs.pkgsi686Linux;
        [ libva-vdpau-driver libvdpau-va-gl ]
        ++ optionals isAmd [ libvdpau vaapiVdpau ];
    };

    services.xserver.videoDrivers = mkIf isNvidia [ "nvidia" ];

    # For a Turing mobile GPU, the proprietary kernel module is still the safer
    # default for Steam/Proton than the open variant.
    hardware.nvidia = mkIf isNvidia {
      modesetting.enable = true;
      open = mkDefault false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement = {
        enable = false;
        finegrained = false;
      };
    };
  };
}
