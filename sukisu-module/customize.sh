ui_print "- Conceal FlClash TUN Helper"
ui_print "- Install the matching Conceal FlClash Android APK first."
ui_print "- The module starts a root mihomo TUN process through SukiSU Ultra."
ui_print "- Traffic is handled by root-created TUN, not Android VpnService, REDIR, or TPROXY."

MODPATH=${MODPATH:-/data/adb/modules_update/conceal-flclash-tun-helper}

ui_print "- Setting script permissions in $MODPATH"
chmod 0755 "$MODPATH/service.sh" "$MODPATH/action.sh" "$MODPATH/uninstall.sh" "$MODPATH/scripts/flclash-root.sh" "$MODPATH/bin/conceal-flclash-mihomo-arm64"
chmod 0644 "$MODPATH/config.env" "$MODPATH/module.prop"
mkdir -p "/data/user/0/com.github.ychaiyi.conceal_flclash/files/root-module" 2>/dev/null || true
chmod 0777 "/data/user/0/com.github.ychaiyi.conceal_flclash/files/root-module" 2>/dev/null || true

ui_print "- Installed script permissions:"
ls -l "$MODPATH/service.sh" "$MODPATH/action.sh" "$MODPATH/uninstall.sh" "$MODPATH/scripts/flclash-root.sh" "$MODPATH/bin/conceal-flclash-mihomo-arm64" | while read -r line; do
  ui_print "  $line"
done
