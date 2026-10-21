# 引导：GRUB + 自签 Secure Boot + ACPI DSDT 双路注入
#
#   Linux  : dsdt.aml 打进 initrd（kernel/firmware/acpi/），内核启动时覆盖
#   Windows: GRUB 用 acpi 命令在 chainload 前注入（/efi/dsdt.aml）
{ pkgs, ... }:

let
  espUuid = "9C35-4F77";
  rootUuid = "724b4e5f-3e76-4ac0-8ed7-ea74201deee2";

  # 内核只从「未压缩」的 early initramfs 里读 ACPI 覆盖表，
  # 所以必须用 boot.initrd.prepend，不能塞进压缩的 initrd。
  acpiOverride = pkgs.runCommand "acpi-dsdt-initrd" { } ''
    mkdir -p kernel/firmware/acpi
    cp ${../../firmware/dsdt.aml} kernel/firmware/acpi/dsdt.aml
    find kernel | ${pkgs.cpio}/bin/cpio -o -H newc --quiet > $out
  '';
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;

    kernelParams = [
      "quiet"
      "loglevel=3"
      "amd_pstate=active"
    ];

    # 修复 TC-O4M 主板 PEGP._DSM 死循环，否则启动卡 30 秒
    initrd.prepend = [ acpiOverride ];

    loader = {
      timeout = 5;

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = false;

        default = "saved";
        configurationLimit = 5;

        extraConfig = ''
          # ---------------------------------------------------------------
          # Windows：GRUB 注入 ACPI 表后再交给 Windows Boot Manager
          # ---------------------------------------------------------------
          menuentry "Windows 10/11 (ACPI Inject)" --class windows --class os {
            insmod part_gpt
            insmod fat
            insmod acpi
            insmod chain
            search --no-floppy --fs-uuid --set=root ${espUuid}
            acpi /dsdt.aml
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }

          # ---------------------------------------------------------------
          # 过渡期：链到 Arch 自己的 grub.cfg，Arch 更新内核后无需改这边
          # ---------------------------------------------------------------
          menuentry "Arch Linux (legacy)" --class arch --class os {
            insmod part_gpt
            insmod btrfs
            search --no-floppy --fs-uuid --set=root ${rootUuid}
            configfile /@/boot/grub/grub.cfg
          }

          menuentry "UEFI Firmware Settings" --class efi {
            fwsetup
          }
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    efibootmgr
    sbctl
    sbsigntool
  ];
}
