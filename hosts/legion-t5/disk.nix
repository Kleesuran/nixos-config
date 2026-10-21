# 磁盘布局：与 Arch 共用同一套子卷，NixOS 只新增 @nixos / @nix / @boot
# 数据子卷挂载点与 Arch 保持一致，避免共用 @home 时路径不一致
{ ... }:

let
  disk = "/dev/disk/by-uuid/724b4e5f-3e76-4ac0-8ed7-ea74201deee2";
  btrfs = subvol: [
    "subvol=${subvol}"
    "compress=zstd:3"
    "noatime"
    "ssd"
    "discard=async"
  ];

  # GRUB 直接从 btrfs 读取 grubenv；内联或压缩 extent 会让 GRUB 2.14 的
  # loadenv 报 "sparse file not allowed"，所以 /boot 单独禁用压缩和内联。
  btrfsBoot = [
    "subvol=@boot"
    "max_inline=0"
    "noatime"
    "ssd"
    "discard=async"
  ];
in
{
  fileSystems = {
    "/" = {
      device = disk;
      fsType = "btrfs";
      options = btrfs "@nixos";
    };

    "/nix" = {
      device = disk;
      fsType = "btrfs";
      options = btrfs "@nix";
      neededForBoot = true;
    };

    "/boot" = {
      device = disk;
      fsType = "btrfs";
      options = btrfsBoot;
      neededForBoot = true;
    };

    "/home" = {
      device = disk;
      fsType = "btrfs";
      options = btrfs "@home";
    };

    "/mnt/steam" = {
      device = disk;
      fsType = "btrfs";
      options = btrfs "@steam";
      noCheck = true;
    };

    "/mnt/containers" = {
      device = disk;
      fsType = "btrfs";
      options = btrfs "@containers";
      noCheck = true;
    };

    "/mnt/repos" = {
      device = disk;
      fsType = "btrfs";
      options = btrfs "@repos";
      noCheck = true;
    };

    "/mnt/vms" = {
      device = disk;
      fsType = "btrfs";
      options = btrfs "@vms";
      noCheck = true;
    };

    # ESP：只放引导器与 dsdt.aml，内核在 @boot
    "/efi" = {
      device = "/dev/disk/by-uuid/9C35-4F77";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
        "nofail"
      ];
      neededForBoot = true;
    };

    "/mnt/windows" = {
      device = "/dev/disk/by-uuid/D834B86134B843F2";
      fsType = "ntfs3";
      options = [
        "uid=1000"
        "gid=100"
        "dmask=0022"
        "fmask=0133"
        "windows_names"
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=5s"
      ];
    };

    "/mnt/data" = {
      device = "/dev/disk/by-uuid/3C78365578360E60";
      fsType = "ntfs3";
      options = [
        "uid=1000"
        "gid=100"
        "dmask=000"
        "fmask=000"
        "windows_names"
        "nofail"
      ];
    };

    "/mnt/HDD" = {
      device = "/dev/disk/by-uuid/1F3368C53EC749BF";
      fsType = "ntfs3";
      options = [
        "uid=1000"
        "gid=100"
        "dmask=000"
        "fmask=000"
        "windows_names"
        "nofail"
      ];
    };
  };

  boot.supportedFilesystems = [
    "btrfs"
    "ntfs3"
    "exfat"
    "vfat"
  ];
}
