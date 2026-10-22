#!/usr/bin/env bash
# mihomo-try: 校验配置 -> 部署到 /etc/mihomo -> 重启服务 -> 测连通
set -euo pipefail

usage() {
  cat <<'EOF'
用法: mihomo-try [选项]

默认读取 ~/.config/mihomo/config.yaml，校验通过后部署到
/etc/mihomo/config.yaml，重启 mihomo.service，并通过代理做连通性测试。
首次运行时若默认配置不存在，会生成一份直连模板。

选项:
  -f, --config PATH   指定配置文件（默认 ~/.config/mihomo/config.yaml）
  -u, --test-url URL  测试 URL（默认 https://www.gstatic.com/generate_204）
  -n, --dry-run       只校验配置，不部署、不重启
  -s, --status        只显示服务状态和最近日志
  -h, --help          显示本帮助

重复尝试: 修改配置后再次执行即可；校验失败时不会改动 /etc/mihomo。
EOF
}

config=""
test_url="https://www.gstatic.com/generate_204"
dry_run=0
show_status=0

while [ $# -gt 0 ]; do
  case "$1" in
    -f|--config)
      config=${2:?缺少参数}
      shift 2
      ;;
    -u|--test-url)
      test_url=${2:?缺少参数}
      shift 2
      ;;
    -n|--dry-run)
      dry_run=1
      shift
      ;;
    -s|--status)
      show_status=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

default_config="${XDG_CONFIG_HOME:-$HOME/.config}/mihomo/config.yaml"
if [ -z "$config" ]; then
  config=$default_config
fi

curl_bin=$(command -v curl)
install_bin=$(command -v install)
systemctl_bin=$(command -v systemctl)
journalctl_bin=$(command -v journalctl)

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    /run/wrappers/bin/sudo "$@"
  fi
}

service_logs() {
  "$systemctl_bin" status mihomo --no-pager 2>&1 | head -n 15 || true
  echo "--- 最近日志 ---"
  "$journalctl_bin" -u mihomo -n 40 --no-pager 2>&1 | tail -n 40 || true
}

if [ "$show_status" -eq 1 ]; then
  service_logs
  exit 0
fi

if [ ! -e "$config" ]; then
  if [ "$config" != "$default_config" ]; then
    echo "配置文件不存在: $config" >&2
    exit 2
  fi
  mkdir -p "$(dirname "$config")"
  cat > "$config" <<'YAML'
# mihomo 配置（mihomo-try 首次运行生成的直连模板）
# 填入 proxies / proxy-groups，或替换为你的订阅配置后重新运行 mihomo-try。
mixed-port: 7890
allow-lan: false
bind-address: '*'
mode: rule
log-level: info
ipv6: false
external-controller: 127.0.0.1:9090
secret: ""
dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - 223.5.5.5
    - 119.29.29.29
proxies: []
proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - DIRECT
rules:
  - MATCH,DIRECT

# TUN 模式（服务已授予 CAP_NET_ADMIN）：
# tun:
#   enable: true
#   stack: mixed
#   auto-route: true
#   auto-detect-interface: true
YAML
  echo "已生成直连模板: $config"
  echo "填入代理后重新运行；本次先按模板校验并部署。"
fi

echo "==> 校验配置: $config"
mihomo -t -d "$(dirname "$config")" -f "$config"

if [ "$dry_run" -eq 1 ]; then
  echo "校验通过（dry-run，未部署）。"
  exit 0
fi

mixed_port=$(sed -nE 's/^[[:space:]]*mixed-port:[[:space:]]*([0-9]+).*/\1/p' "$config" | head -n 1)
mixed_port=${mixed_port:-7890}

api_ctl=""
if grep -qE '^[[:space:]]*external-controller:[[:space:]]*' "$config"; then
  api_ctl=$(sed -nE 's/^[[:space:]]*external-controller:[[:space:]]*//p' "$config" | head -n 1 \
    | sed -E 's/[[:space:]]+#.*$//; s/[[:space:]]+$//' | tr -d "\"'")
  api_ctl=${api_ctl/0.0.0.0/127.0.0.1}
fi

secret=$(sed -nE 's/^[[:space:]]*secret:[[:space:]]*//p' "$config" | head -n 1 \
  | sed -E 's/[[:space:]]+#.*$//; s/[[:space:]]+$//' | tr -d "\"'")

echo "==> 部署到 /etc/mihomo/config.yaml"
as_root "$install_bin" -Dm600 "$config" /etc/mihomo/config.yaml

echo "==> 重启 mihomo.service"
as_root "$systemctl_bin" restart mihomo

auth=()
if [ -n "$secret" ]; then
  auth=(-H "Authorization: Bearer $secret")
fi

if [ -n "$api_ctl" ]; then
  api_ready=0
  for _ in $(seq 1 20); do
    if "$curl_bin" --noproxy '*' -fsS "${auth[@]}" "http://$api_ctl/version" >/dev/null 2>&1; then
      api_ready=1
      break
    fi
    sleep 1
  done
  if [ "$api_ready" -ne 1 ]; then
    echo "FAIL: API 未就绪（$api_ctl）" >&2
    service_logs >&2
    exit 1
  fi
  echo -n "API 版本: "
  "$curl_bin" --noproxy '*' -fsS "${auth[@]}" "http://$api_ctl/version" || true
  echo
else
  sleep 2
fi

echo "==> 通过 127.0.0.1:$mixed_port 测试 $test_url"
code=""
if ! code=$("$curl_bin" -x "http://127.0.0.1:$mixed_port" --noproxy '' -fsS \
  -o /dev/null -w '%{http_code}' --max-time 20 "$test_url" 2>/dev/null); then
  code=""
fi

if [ -n "$code" ] && [ "$code" -ge 200 ] && [ "$code" -lt 400 ]; then
  echo "OK: 代理链路可用（HTTP $code）"
  exit 0
fi

echo "FAIL: 代理链路不可用" >&2
echo "直连对照:" >&2
if ! "$curl_bin" -fsS -o /dev/null -w '  direct HTTP %{http_code} in %{time_total}s\n' \
  --max-time 10 "$test_url" 2>/dev/null; then
  echo "  direct 也失败（网络本身可能不可达）" >&2
fi
service_logs >&2
exit 1
