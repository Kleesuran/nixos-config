# Podman（rootless 为主）
#
# 镜像存储沿用 Arch 时代的那份：rootless podman 读的是
# ~/.config/containers/storage.conf（Arch 留下的文件已把 graphroot 指到
# ~/containers/storage → /mnt/containers/storage），而 /etc 下这份只对 rootful 生效。
# 所以这里**不**覆盖 graphroot，免得 rootful 和 rootless 抢同一个存储。
#
# 要用 compose / k3d，需要 user 级 socket：
#   systemctl --user enable --now podman.socket
#   export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
{ ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # 提供 docker 命令别名，供 docker-compose / k3d 识别
  };
}
