# 蓝牙 LHDC v5（OPPO Enco R3 Pro）
#
# 上游 PipeWire 1.6.9 不含 LHDC，这里用 pkgs/pipewire-lhdc 顶替。
# 1.4 之后蓝牙 codec 协商在 WirePlumber 进程里，SPA 插件目录又来自 libspa-support
# 的编译期默认值，所以 wireplumber 必须链接同一份自定义构建，不能只换 daemon。
{ pkgs, ... }:

{
  services.pipewire = {
    package = pkgs.pipewire-lhdc;
    wireplumber.package = pkgs.wireplumber.override { pipewire = pkgs.pipewire-lhdc; };
  };
}
