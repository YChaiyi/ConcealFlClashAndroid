package com.follow.clash.common


import android.app.Application
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers

object GlobalState : CoroutineScope by CoroutineScope(Dispatchers.Default) {

    const val NOTIFICATION_CHANNEL = "ConcealFlClash"

    const val NOTIFICATION_ID = 1

    val packageName: String
        get() = application.packageName

    val RECEIVE_BROADCASTS_PERMISSIONS: String
        get() = "${packageName}.permission.RECEIVE_BROADCASTS"


    private var _application: Application? = null

    val application: Application
        get() = _application!!


    fun log(text: String) {
        Log.d("[ConcealFlClash]", text)
    }

    fun init(application: Application) {
        _application = application
    }

    fun setCrashlytics(enable: Boolean) {
        if (enable) {
            log("crashlytics is disabled in Conceal FlClash Android builds")
        }
    }
}
