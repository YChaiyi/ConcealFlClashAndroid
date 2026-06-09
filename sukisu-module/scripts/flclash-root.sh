#!/system/bin/sh

SCRIPT_DIR=${0%/*}
if [ "$SCRIPT_DIR" = "$0" ]; then
  SCRIPT_DIR=.
fi
MODDIR=${MODDIR:-${SCRIPT_DIR%/scripts}}

[ -f "$MODDIR/config.env" ] && . "$MODDIR/config.env"

FLCLASH_PACKAGE=${FLCLASH_PACKAGE:-com.github.ychaiyi.conceal_flclash}
FLCLASH_AUTO_START=${FLCLASH_AUTO_START:-1}
FLCLASH_AUTO_START_RETRY=${FLCLASH_AUTO_START_RETRY:-1}
FLCLASH_WAIT_CONFIG_SECONDS=${FLCLASH_WAIT_CONFIG_SECONDS:-60}
FLCLASH_WAIT_TUN_SECONDS=${FLCLASH_WAIT_TUN_SECONDS:-45}
FLCLASH_APP_DATA_DIR=${FLCLASH_APP_DATA_DIR:-/data/user/0/$FLCLASH_PACKAGE}
FLCLASH_APP_DIR=${FLCLASH_APP_DIR:-$FLCLASH_APP_DATA_DIR/files}
FLCLASH_SOURCE_CONFIG=${FLCLASH_SOURCE_CONFIG:-$FLCLASH_APP_DIR/config.yaml}
FLCLASH_CONTROL_DIR=${FLCLASH_CONTROL_DIR:-$FLCLASH_APP_DIR/root-module}
FLCLASH_CONTROL_REQUEST=${FLCLASH_CONTROL_REQUEST:-$FLCLASH_CONTROL_DIR/request}
FLCLASH_CONTROL_STATUS=${FLCLASH_CONTROL_STATUS:-$FLCLASH_CONTROL_DIR/status}
FLCLASH_BINARY=${FLCLASH_BINARY:-$MODDIR/bin/conceal-flclash-mihomo-arm64}
FLCLASH_RUN_DIR=${FLCLASH_RUN_DIR:-$MODDIR/run}
FLCLASH_ROOT_CONFIG=${FLCLASH_ROOT_CONFIG:-$FLCLASH_RUN_DIR/config.yaml}
FLCLASH_PID_FILE=${FLCLASH_PID_FILE:-$FLCLASH_RUN_DIR/mihomo.pid}
FLCLASH_MONITOR_PID_FILE=${FLCLASH_MONITOR_PID_FILE:-$FLCLASH_RUN_DIR/monitor.pid}
FLCLASH_LOG_FILE=${FLCLASH_LOG_FILE:-$MODDIR/flclash-tun.log}
FLCLASH_CONTROL_INTERVAL=${FLCLASH_CONTROL_INTERVAL:-2}
FLCLASH_LOG_LEVEL=${FLCLASH_LOG_LEVEL:-info}
FLCLASH_INCLUDE_ANDROID_USERS=${FLCLASH_INCLUDE_ANDROID_USERS:-0}
FLCLASH_EXCLUDE_UIDS=${FLCLASH_EXCLUDE_UIDS:-}
FLCLASH_EXCLUDE_UID_RANGES=${FLCLASH_EXCLUDE_UID_RANGES:-0:9999}
FLCLASH_IPROUTE_TABLE=${FLCLASH_IPROUTE_TABLE:-2022}
FLCLASH_IPROUTE_RULE_START=${FLCLASH_IPROUTE_RULE_START:-9000}
FLCLASH_IPROUTE_RULE_END=${FLCLASH_IPROUTE_RULE_END:-9010}
FLCLASH_DNS_LISTEN=${FLCLASH_DNS_LISTEN-}
FLCLASH_DNS_ENHANCED_MODE=${FLCLASH_DNS_ENHANCED_MODE:-redir-host}
FLCLASH_FORCE_SNIFFER=${FLCLASH_FORCE_SNIFFER:-1}
FLCLASH_TUN_STACK=${FLCLASH_TUN_STACK:-gvisor}

LEGACY_CHAINS="FLCLASH_OUT FLCLASH_PRE FLCLASH_DNS_OUT FLCLASH_DNS_PRE"

log() {
  msg="[flclash-tun] $*"
  echo "$msg"
  if [ -n "$MODDIR" ] && [ -d "$MODDIR" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$FLCLASH_LOG_FILE" 2>/dev/null
  fi
}

run() {
  "$@" >/dev/null 2>&1
}

ensure_control_paths() {
  mkdir -p "$FLCLASH_CONTROL_DIR" >/dev/null 2>&1
  chmod 0777 "$FLCLASH_CONTROL_DIR" >/dev/null 2>&1
  app_uid=$(stat -c '%u' "$FLCLASH_APP_DATA_DIR" 2>/dev/null)
  if [ -n "$app_uid" ]; then
    chown "$app_uid:$app_uid" "$FLCLASH_APP_DIR" "$FLCLASH_CONTROL_DIR" >/dev/null 2>&1 || true
  fi
}

delete_rule() {
  while "$@" >/dev/null 2>&1; do
    :
  done
}

package_installed() {
  pm path "$FLCLASH_PACKAGE" >/dev/null 2>&1
}

wait_boot() {
  count=0
  while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$count" -lt 90 ]; do
    sleep 2
    count=$((count + 1))
  done
}

wait_package() {
  count=0
  until package_installed; do
    if [ "$count" -ge 60 ]; then
      log "package $FLCLASH_PACKAGE is not installed"
      return 1
    fi
    sleep 2
    count=$((count + 1))
  done
}

grant_notification() {
  pm grant "$FLCLASH_PACKAGE" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
}

ensure_paths() {
  mkdir -p "$FLCLASH_RUN_DIR" "$MODDIR/bin" >/dev/null 2>&1
  ensure_control_paths
  if [ ! -x "$FLCLASH_BINARY" ]; then
    log "root binary is missing or not executable: $FLCLASH_BINARY"
    return 1
  fi

  count=0
  while [ ! -f "$FLCLASH_SOURCE_CONFIG" ] && [ "$count" -lt "$FLCLASH_WAIT_CONFIG_SECONDS" ]; do
    if [ "$count" -eq 0 ]; then
      log "waiting for app config: $FLCLASH_SOURCE_CONFIG"
    fi
    sleep 1
    count=$((count + 1))
  done

  if [ ! -f "$FLCLASH_SOURCE_CONFIG" ]; then
    log "app config is missing: $FLCLASH_SOURCE_CONFIG"
    return 1
  fi
}

write_status() {
  ensure_control_paths
  [ -d "$FLCLASH_CONTROL_DIR" ] || return 0
  if pid_running && tun_active; then
    printf 'running\n' > "$FLCLASH_CONTROL_STATUS" 2>/dev/null
  else
    printf 'stopped\n' > "$FLCLASH_CONTROL_STATUS" 2>/dev/null
  fi
  chmod 0666 "$FLCLASH_CONTROL_STATUS" >/dev/null 2>&1
  app_uid=$(stat -c '%u' "$FLCLASH_APP_DATA_DIR" 2>/dev/null)
  if [ -n "$app_uid" ]; then
    chown "$app_uid:$app_uid" "$FLCLASH_CONTROL_STATUS" >/dev/null 2>&1 || true
  fi
}

cleanup_legacy_rules() {
  for chain in $LEGACY_CHAINS; do
    delete_rule iptables -t nat -D OUTPUT -j "$chain"
    delete_rule iptables -t nat -D PREROUTING -j "$chain"
    run iptables -t nat -F "$chain"
    run iptables -t nat -X "$chain"

    delete_rule ip6tables -t nat -D OUTPUT -j "$chain"
    delete_rule ip6tables -t nat -D PREROUTING -j "$chain"
    run ip6tables -t nat -F "$chain"
    run ip6tables -t nat -X "$chain"
  done
}

cleanup_tun_routes() {
  pref="$FLCLASH_IPROUTE_RULE_START"
  while [ "$pref" -le "$FLCLASH_IPROUTE_RULE_END" ]; do
    delete_rule ip rule del pref "$pref"
    pref=$((pref + 1))
  done
  run ip route flush table "$FLCLASH_IPROUTE_TABLE"
  run ip -6 route flush table "$FLCLASH_IPROUTE_TABLE"
}

tun_active() {
  ip link show 2>/dev/null | grep -Eq '^[0-9]+: ConcealFlClash:'
}

pid_running() {
  [ -f "$FLCLASH_PID_FILE" ] || return 1
  pid=$(cat "$FLCLASH_PID_FILE" 2>/dev/null)
  [ -n "$pid" ] || return 1
  kill -0 "$pid" >/dev/null 2>&1
}

monitor_running() {
  [ -f "$FLCLASH_MONITOR_PID_FILE" ] || return 1
  monitor_pid=$(cat "$FLCLASH_MONITOR_PID_FILE" 2>/dev/null)
  [ -n "$monitor_pid" ] || return 1
  [ "$monitor_pid" != "$$" ] || return 1
  kill -0 "$monitor_pid" >/dev/null 2>&1
}

wait_tun() {
  count=0
  while [ "$count" -lt "$FLCLASH_WAIT_TUN_SECONDS" ]; do
    if tun_active; then
      log "TUN interface is active"
      return 0
    fi
    sleep 1
    count=$((count + 1))
  done

  log "TUN interface did not appear"
  return 1
}

yaml_list() {
  key="$1"
  values="$2"
  items=$(printf '%s\n' "$values" | tr ',' ' ' | tr ' ' '\n' | sed '/^$/d; s/^/    - /')
  [ -n "$items" ] || return 0
  printf '  %s:\n%s\n' "$key" "$items"
}

write_root_config() {
  tmp="$FLCLASH_ROOT_CONFIG.tmp"
  awk -v log_level="$FLCLASH_LOG_LEVEL" -v dns_listen="$FLCLASH_DNS_LISTEN" -v dns_enhanced_mode="$FLCLASH_DNS_ENHANCED_MODE" -v force_sniffer="$FLCLASH_FORCE_SNIFFER" '
    /^[^[:space:]#][^:]*:/ {
      if (skip == 1) {
        skip = 0
      }
      in_dns = ($0 ~ /^dns:[[:space:]]*$/)
    }
    /^tun:[[:space:]]*$/ { skip = 1; next }
    /^iptables:[[:space:]]*$/ { skip = 1; next }
    force_sniffer == 1 && /^sniffer:[[:space:]]*$/ { skip = 1; next }
    skip == 1 { next }
    /^mixed-port:/ { print "mixed-port: 0"; next }
    /^port:/ { print "port: 0"; next }
    /^socks-port:/ { print "socks-port: 0"; next }
    /^redir-port:/ { print "redir-port: 0"; next }
    /^tproxy-port:/ { print "tproxy-port: 0"; next }
    /^external-controller:/ { print "external-controller: \"\""; next }
    /^log-level:/ { print "log-level: " log_level; seen_log_level = 1; next }
    in_dns == 1 && /^[[:space:]]+listen:/ { print "  listen: \"" dns_listen "\""; next }
    in_dns == 1 && dns_enhanced_mode != "" && /^[[:space:]]+enhanced-mode:/ { print "  enhanced-mode: \"" dns_enhanced_mode "\""; next }
    { print }
    END {
      if (seen_log_level != 1) {
        print "log-level: " log_level
      }
    }
  ' "$FLCLASH_SOURCE_CONFIG" > "$tmp" || return 1

  cat >> "$tmp" <<EOF
iptables:
  enable: false
tun:
  enable: true
  device: "ConcealFlClash"
  stack: "$FLCLASH_TUN_STACK"
  iproute2-table-index: $FLCLASH_IPROUTE_TABLE
  iproute2-rule-index: $FLCLASH_IPROUTE_RULE_START
  dns-hijack:
    - "any:53"
  auto-route: true
  auto-detect-interface: true
  strict-route: false
  mtu: 9000
$(yaml_list "include-android-user" "$FLCLASH_INCLUDE_ANDROID_USERS")
$(yaml_list "exclude-uid" "$FLCLASH_EXCLUDE_UIDS")
$(yaml_list "exclude-uid-range" "$FLCLASH_EXCLUDE_UID_RANGES")
EOF

  if [ "$FLCLASH_FORCE_SNIFFER" = "1" ]; then
    cat >> "$tmp" <<'EOF'
sniffer:
  enable: true
  override-destination: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    TLS: {}
    QUIC: {}
    HTTP:
      ports:
        - 80
        - 8080-8880
      override-destination: true
EOF
  fi

  mv "$tmp" "$FLCLASH_ROOT_CONFIG"
  chmod 0600 "$FLCLASH_ROOT_CONFIG" >/dev/null 2>&1
}

start_root_tun() {
  wait_boot
  wait_package || return 1
  grant_notification
  ensure_paths || return 1
  cleanup_legacy_rules
  cleanup_tun_routes
  if pid_running && tun_active; then
    log "already running"
    return 0
  fi
  stop_root_tun >/dev/null 2>&1 || true
  write_root_config || {
    log "failed to write root config"
    return 1
  }
  : > "$FLCLASH_LOG_FILE"
  chmod 0600 "$FLCLASH_LOG_FILE" >/dev/null 2>&1
  (
    cd "$FLCLASH_APP_DIR" || exit 1
    export CONCEAL_FLCLASH_ROOT_TUN=1
    export DISABLE_OVERRIDE_ANDROID_VPN=0
    exec "$FLCLASH_BINARY" -d "$FLCLASH_APP_DIR" -f "$FLCLASH_ROOT_CONFIG"
  ) >> "$FLCLASH_LOG_FILE" 2>&1 &
  echo "$!" > "$FLCLASH_PID_FILE"
  chmod 0600 "$FLCLASH_PID_FILE" >/dev/null 2>&1
  if wait_tun; then
    write_status
    return 0
  fi
  stop_root_tun >/dev/null 2>&1 || true
  write_status
  return 1
}

stop_root_tun() {
  cleanup_legacy_rules
  if [ -f "$FLCLASH_PID_FILE" ]; then
    pid=$(cat "$FLCLASH_PID_FILE" 2>/dev/null)
    if [ -n "$pid" ]; then
      kill "$pid" >/dev/null 2>&1
      sleep 1
      kill -9 "$pid" >/dev/null 2>&1
    fi
    rm -f "$FLCLASH_PID_FILE"
  fi
  cleanup_tun_routes
  if tun_active; then
    log "stop sent; TUN is still active"
  else
    log "stopped"
  fi
  write_status
}

toggle_root_tun() {
  if pid_running || tun_active; then
    stop_root_tun
  else
    start_root_tun
  fi
}

boot_start() {
  if monitor_running; then
    log "monitor already running"
    exit 0
  fi
  mkdir -p "$FLCLASH_RUN_DIR" >/dev/null 2>&1
  echo "$$" > "$FLCLASH_MONITOR_PID_FILE"
  chmod 0600 "$FLCLASH_MONITOR_PID_FILE" >/dev/null 2>&1
  wait_boot
  cleanup_legacy_rules
  cleanup_tun_routes
  ensure_paths >/dev/null 2>&1 || true
  write_status
  boot_autostart_pending=0
  if [ "$FLCLASH_AUTO_START" = "1" ]; then
    if start_root_tun; then
      boot_autostart_pending=0
    elif [ "$FLCLASH_AUTO_START_RETRY" = "1" ]; then
      boot_autostart_pending=1
      log "auto start is pending until app config becomes available"
    fi
  else
    log "auto start is disabled"
  fi
  control_loop
}

retry_boot_autostart() {
  [ "$boot_autostart_pending" = "1" ] || return 1
  [ "$FLCLASH_AUTO_START" = "1" ] || {
    boot_autostart_pending=0
    return 1
  }
  if pid_running && tun_active; then
    boot_autostart_pending=0
    return 0
  fi
  package_installed || return 1
  [ -f "$FLCLASH_SOURCE_CONFIG" ] || return 1
  if start_root_tun; then
    boot_autostart_pending=0
    return 0
  fi
  return 1
}

handle_control_request() {
  [ -f "$FLCLASH_CONTROL_REQUEST" ] || return 1
  request=$(head -n 1 "$FLCLASH_CONTROL_REQUEST" 2>/dev/null | tr -d '\r\n ')
  rm -f "$FLCLASH_CONTROL_REQUEST" >/dev/null 2>&1
  case "$request" in
    start)
      boot_autostart_pending=0
      start_root_tun || true
      ;;
    stop)
      boot_autostart_pending=0
      stop_root_tun || true
      ;;
    restart)
      boot_autostart_pending=0
      stop_root_tun >/dev/null 2>&1 || true
      start_root_tun || true
      ;;
    status)
      write_status
      ;;
    "")
      return 1
      ;;
    *)
      log "ignored unknown control request: $request"
      write_status
      ;;
  esac
}

control_loop() {
  while true; do
    handle_control_request >/dev/null 2>&1 || {
      retry_boot_autostart >/dev/null 2>&1 || true
      write_status
    }
    sleep "$FLCLASH_CONTROL_INTERVAL"
  done
}

case "$1" in
  start)
    start_root_tun
    ;;
  stop)
    stop_root_tun
    ;;
  restart)
    stop_root_tun
    start_root_tun
    ;;
  toggle)
    toggle_root_tun
    ;;
  status)
    if pid_running && tun_active; then
      log "running"
      write_status
      exit 0
    fi
    log "stopped"
    write_status
    exit 1
    ;;
  status-file)
    write_status
    ;;
  cleanup)
    cleanup_legacy_rules
    ;;
  monitor)
    boot_start
    ;;
  *)
    echo "usage: $0 {start|stop|restart|toggle|status|cleanup|monitor}"
    exit 2
    ;;
esac
