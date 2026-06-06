#!/system/bin/sh

MODDIR=${0%/*}
export MODDIR

"$MODDIR/scripts/flclash-root.sh" stop
