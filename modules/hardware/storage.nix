# 老盘（/dev/sda，WDC WD5003ABYX-01WERA1）的块层保守设置
#
# 这块盘 SATA 链路已降级到 1.5Gbps，并出现过 tag timeout / READ aborted。
# disk.nix 的挂载参数只能减少元数据压力，真正决定「单次命令代价」的是块层：
#   - max_sectors_kb 默认 4096（一条 I/O 最多 4MB），降到 256 后超时只影响小请求，
#     重试代价低，也不容易把整段读拖死；
#   - 调度器从 bfq 换成 mq-deadline，更适合单队列的老机械盘。
# 按序列号匹配，避免 sda/sdb 字母顺序变化。
{ ... }:

{
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd*", ATTRS{serial}=="WD-WCC6YKDREJKI", ATTR{queue/scheduler}="mq-deadline", ATTR{queue/max_sectors_kb}="256"
  '';
}
