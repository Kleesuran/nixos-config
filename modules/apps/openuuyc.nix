# OpenUUYC 被控端（Linux 版，djkcyl/farwing PR #1）
#
# 主要用途是本机被控：画面/键鼠/声音/文件都由登录后的图形会话提供，
# 所以自启单元挂在 graphical-session.target 上，而不是开机常驻服务。
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.openuuyc ];

  # Wayland 下键鼠经 /dev/uinput 注入；Xorg 用 XTest，不需要这一步。
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"
  '';

  # 这份单元会被程序识别为“发行版安装的单元”（/etc/systemd/user 在它的
  # 搜索列表里），程序内的“开机自启”开关只做 enable/disable，不会另写一份
  # 指向未包装二进制的 unit。
  systemd.user.services.openuuyc = {
    description = "OpenUUYC 远程被控";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" "xdg-desktop-portal.service" ];
    unitConfig = {
      ConditionFileIsExecutable = "${pkgs.openuuyc}/bin/OpenUUYC";
      StartLimitIntervalSec = 500;
      StartLimitBurst = 5;
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.openuuyc}/bin/OpenUUYC gui --background";
      Restart = "on-failure";
      RestartSec = 5;
      # 显示恢复守护会 process_group(0) 脱离，xdg-open 打开的浏览器也不该跟着退。
      KillMode = "process";
    };
  };
}
