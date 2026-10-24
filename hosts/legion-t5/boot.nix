# 引导：GRUB + 自签 Secure Boot + ACPI DSDT 双路注入
#
#   Linux  : dsdt.aml 打进 initrd（kernel/firmware/acpi/），内核启动时覆盖
#   Windows: GRUB 用 acpi 命令在 chainload 前注入（/efi/dsdt.aml）
#
# 本文件同时负责本机专属的定制 GRUB core：它的内嵌 early config 写死了这条
# 磁盘的 UUID 与 @boot 子卷，Secure Boot 重签的通用逻辑在 modules/security/。
{ config, lib, pkgs, ... }:

let
  espUuid = "9C35-4F77";
  esp = config.boot.loader.efi.efiSysMountPoint;

  # 从原 Arch 定制 GRUB 里取出的、去掉了 lockdown 注册的 acpi 模块，
  # 与 stock GRUB 2.14 模块重新打包成这个 core。详见 firmware/grub-custom/README.md。
  customGrub = ../../firmware/grub-custom/core.efi;

  # 先装 core，再由 modules/security 的 signGrub 签名（mkBefore 保证顺序）。
  installCustomGrub = pkgs.writeShellScript "install-custom-grub" ''
    set -eu

    dst=${esp}/EFI/NixOS-efi/grubx64.efi
    key=/var/lib/sbctl/keys/db/db.key
    cert=/var/lib/sbctl/keys/db/db.pem

    [ -d ${esp}/EFI ] || { echo "${esp} 未挂载，跳过自定义 GRUB"; exit 0; }

    tmp="$dst.tmp"
    ${pkgs.coreutils}/bin/install -Dm644 ${customGrub} "$tmp"

    if [ ! -f "$key" ]; then
      echo "sbctl 密钥不存在，保留 stock GRUB"
      ${pkgs.coreutils}/bin/rm -f "$tmp"
      exit 0
    fi

    # 先签临时文件并验证，成功后才替换，避免把未签名/损坏的核心写到 ESP
    ${pkgs.sbsigntool}/bin/sbsign --key "$key" --cert "$cert" \
      --output "$tmp.signed" "$tmp"
    ${pkgs.sbsigntool}/bin/sbverify --cert "$cert" "$tmp.signed" >/dev/null
    ${pkgs.coreutils}/bin/mv "$tmp.signed" "$dst"
    ${pkgs.coreutils}/bin/rm -f "$tmp"
    echo "installed custom GRUB: $dst"
  '';

  # GRUB 2.14 在 --disable-shim-lock 下仍要求有验证器处理动态模块，
  # 并把 normal 等菜单所需模块一起装进已签名的核心，避免从 /boot 动态加载。
  grubModules = "normal tpm linux boot btrfs part_gpt fat acpi chain configfile loadenv search search_fs_uuid search_label test echo font gfxterm png efi_gop efi_uga all_video gfxmenu gfxterm_background minicmd ext2 xfs ntfs zstd efifwsetup halt reboot sleep gettext";

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
    ];

    # 修复 TC-O4M 主板 PEGP._DSM 死循环，否则启动卡 30 秒
    initrd.prepend = [ "${acpiOverride}" ];

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

        # 自定义 core 由本文件安装，签名交给 modules/security/secureboot.nix。
        # mkBefore 保证「先装再签」，不依赖模块 import 顺序。
        # 这里保留 stock 安装参数只是为了 grub-install 仍能生成完整的 /boot 结构。
        extraInstallCommands = lib.mkBefore ''
          ${installCustomGrub}
        '';

        extraGrubInstallArgs = [
          "--disable-shim-lock"
          "--modules=${grubModules}"
        ];

        # 不能用 "saved"：GRUB 的 btrfs 驱动没有实现 read_hook，save_env 收集
        # 不到 blocklist，每次 savedefault 都会报 "sparse file not allowed"
        # 并中断菜单项（与 grubenv 是否内联/压缩无关）。
        default = "NixOS";
        configurationLimit = 5;

        # extraEntries 默认排在默认 NixOS 条目之后，保证 NixOS 是第一项。
        extraEntries = ''
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

          menuentry "UEFI Firmware Settings" --class efi {
            fwsetup
          }
        '';
      };
    };
  };

  # GRUB 的 Windows 条目从 ESP 根目录读取本机 ACPI 表
  system.activationScripts.dsdt = {
    text = ''
      if [ -d ${esp} ]; then
        ${pkgs.coreutils}/bin/install -Dm644 ${../../firmware/dsdt.aml} ${esp}/dsdt.aml
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    efibootmgr
    sbctl
    sbsigntool
  ];
}
