ui_print "- Conceal FlClash TUN Helper"
ui_print "- Install the matching Conceal FlClash Android APK first."
ui_print "- The module starts Conceal FlClash Android through its quick START action."
ui_print "- Traffic is handled by the app's built-in VpnService TUN, not REDIR/TPROXY rules."

MODPATH=${MODPATH:-/data/adb/modules_update/conceal-flclash-tun-helper}

ui_print "- Setting script permissions in $MODPATH"
chmod 0755 "$MODPATH/service.sh" "$MODPATH/action.sh" "$MODPATH/uninstall.sh" "$MODPATH/scripts/flclash-root.sh"
chmod 0644 "$MODPATH/config.env" "$MODPATH/module.prop"

ui_print "- Installed script permissions:"
ls -l "$MODPATH/service.sh" "$MODPATH/action.sh" "$MODPATH/uninstall.sh" "$MODPATH/scripts/flclash-root.sh" | while read -r line; do
  ui_print "  $line"
done
