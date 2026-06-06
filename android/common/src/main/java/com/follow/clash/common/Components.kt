package com.follow.clash.common

import android.content.ComponentName

object Components {
    const val PACKAGE_NAME = "com.github.ychaiyi.conceal_flclash"
    const val CLASS_PACKAGE_NAME = "com.follow.clash"

    val MAIN_ACTIVITY =
        ComponentName(GlobalState.packageName, "${CLASS_PACKAGE_NAME}.MainActivity")

    val TEMP_ACTIVITY =
        ComponentName(GlobalState.packageName, "${CLASS_PACKAGE_NAME}.TempActivity")

    val BROADCAST_RECEIVER =
        ComponentName(GlobalState.packageName, "${CLASS_PACKAGE_NAME}.BroadcastReceiver")
}
