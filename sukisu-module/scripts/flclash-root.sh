#!/system/bin/sh

SCRIPT_DIR=${0%/*}
if [ "$SCRIPT_DIR" = "$0" ]; then
  SCRIPT_DIR=.
fi
MODDIR=${MODDIR:-${SCRIPT_DIR%/scripts}}

[ -f "$MODDIR/config.env" ] && . "$MODDIR/config.env"

FLCLASH_PACKAGE=${FLCLASH_PACKAGE:-com.github.ychaiyi.conceal_flclash}
FLCLASH_START_ACTION=${FLCLASH_START_ACTION:-$FLCLASH_PACKAGE.action.START}
FLCLASH_STOP_ACTION=${FLCLASH_STOP_ACTION:-$FLCLASH_PACKAGE.action.STOP}
FLCLASH_AUTO_START=${FLCLASH_AUTO_START:-1}
FLCLASH_WAIT_TUN_SECONDS=${FLCLASH_WAIT_TUN_SECONDS:-45}

LEGACY_CHAINS="FLCLASH_OUT FLCLASH_PRE FLCLASH_DNS_OUT FLCLASH_DNS_PRE"

log() {
  msg="[flclash-tun] $*"
  echo "$msg"
  if [ -n "$MODDIR" ] && [ -d "$MODDIR" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$MODDIR/flclash-tun.log" 2>/dev/null
  fi
}

run() {
  "$@" >/dev/null 2>&1
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

tun_active() {
  ip link show 2>/dev/null | grep -Eq '^[0-9]+: tun[0-9]+:'
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

  log "TUN interface did not appear. Open the app once and grant Android VPN consent, then start again."
  return 1
}

start_app_tun() {
  wait_boot
  wait_package || return 1
  grant_notification
  cleanup_legacy_rules
  am start -a "$FLCLASH_START_ACTION" -p "$FLCLASH_PACKAGE" >/dev/null 2>&1 || return 1
  wait_tun
}

stop_app_tun() {
  cleanup_legacy_rules
  run am start -a "$FLCLASH_STOP_ACTION" -p "$FLCLASH_PACKAGE"
  sleep 2
  if tun_active; then
    log "stop action sent; TUN is still active"
  else
    log "stopped"
  fi
}

toggle_app_tun() {
  if tun_active; then
    stop_app_tun
  else
    start_app_tun
  fi
}

boot_start() {
  wait_boot
  cleanup_legacy_rules
  if [ "$FLCLASH_AUTO_START" = "1" ]; then
    start_app_tun || true
  else
    log "auto start is disabled"
  fi
}

case "$1" in
  start)
    start_app_tun
    ;;
  stop)
    stop_app_tun
    ;;
  restart)
    stop_app_tun
    start_app_tun
    ;;
  toggle)
    toggle_app_tun
    ;;
  cleanup)
    cleanup_legacy_rules
    ;;
  monitor)
    boot_start
    ;;
  *)
    echo "usage: $0 {start|stop|restart|toggle|cleanup|monitor}"
    exit 2
    ;;
esac
