# 睡眠唤醒源：只保留电源键
#
# USB 唤醒要关两层门，缺一层都可能被鼠标/键盘/插拔唤醒：
#   1. USB 设备自己：/sys/bus/usb/devices/*/power/wakeup（鼠标、键盘、hub、蓝牙）
#   2. PCI/ACPI 层：xHCI 控制器本机是 02:00.0 (PTXH) 和 08:00.3 (XHC0)，
#      而 08:00.3 的上游桥 00:08.1 (GP13) 还有自己的 _PRW，按设备逐个关不可靠，
#      PCI 层整个关掉。
#
# 代价：Wake-on-LAN / Wake-on-WLAN 一并失效（本机没有用到）。
# 电源键是 ACPI 固定事件，不在 /proc/acpi/wakeup 里，不受影响，仍然能唤醒。
{ ... }:

{
  # 第一层用 udev：USB 设备是热插拔的，插上时驱动会重新打开 remote wakeup。
  # KERNEL!="*:*" 跳过 usb_interface，接口没有 power/wakeup。
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="usb", KERNEL!="*:*", ATTR{power/wakeup}="disabled"
  '';

  # 第二层用开机一次性 job：PCI 设备只在启动时枚举，不需要 udev 常驻；
  # 而且 host bridge 之类的设备根本没有 power/wakeup，写成 udev 规则只会刷日志。
  systemd.services.disable-pci-wakeup = {
    description = "关闭 PCI 唤醒源（睡眠只留电源键可唤醒）";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for f in /sys/bus/pci/devices/*/power/wakeup; do
        if [ -w "$f" ]; then
          echo disabled > "$f"
        fi
      done
    '';
  };
}
