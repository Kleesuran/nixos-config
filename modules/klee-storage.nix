{ config, lib, ... }:

with lib;
let
  cfg = config.device.klee-2070m;
in
{
  options.device.klee-2070m = {
    enable = mkEnableOption "Klee's RTX 2070 Mobile Desktop specific storage mounts";
  };

  config = mkIf cfg.enable {
    # 挂载策略：包含 nofail 和 ntfs3 优化
    fileSystems = {
      # 1. 机械硬盘数据盘 (SATA)
      "/run/media/klee/DATA-HDD" = {
        device = "/dev/disk/by-uuid/DE5807D35807A97B";
        fsType = "ntfs3";
        options = [ "nofail" "x-systemd.device-timeout=5s" "uid=1000" "gid=100" "rw" "user" ];
      };

      # 2. NVMe 系统盘 (Windows 分区)
      "/run/media/klee/SYS-M.2" = {
        device = "/dev/disk/by-uuid/EC5C67745C67388A";
        fsType = "ntfs3";
        options = [ "nofail" "x-systemd.device-timeout=5s" "uid=1000" "gid=100" "rw" "user" ];
      };

      # 3. NVMe 数据盘 (游戏/仓库)
      "/run/media/klee/DATA-M.2" = {
        device = "/dev/disk/by-uuid/0DD8137B0DD8137B";
        fsType = "ntfs3";
        options = [ "nofail" "x-systemd.device-timeout=5s" "uid=1000" "gid=100" "rw" "user" ];
      };

      # 4. 其他固定 NTFS 分区
      "/run/media/klee/Extra-NTFS" = {
        device = "/dev/disk/by-uuid/A430DC5930DC33D0";
        fsType = "ntfs3";
        options = [ "nofail" "x-systemd.device-timeout=5s" "uid=1000" "gid=100" "rw" "user" ];
      };
    };
  };
}
