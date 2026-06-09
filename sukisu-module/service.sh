#!/system/bin/sh

MODDIR=${0%/*}
export MODDIR

SCRIPT="$MODDIR/scripts/flclash-root.sh"

if command -v nohup >/dev/null 2>&1; then
  nohup "$SCRIPT" monitor >/dev/null 2>&1 &
elif command -v setsid >/dev/null 2>&1; then
  setsid "$SCRIPT" monitor >/dev/null 2>&1 &
else
  "$SCRIPT" monitor >/dev/null 2>&1 &
fi
