package com.follow.clash

import com.follow.clash.common.GlobalState
import com.follow.clash.models.SharedState
import com.follow.clash.plugins.TilePlugin
import com.follow.clash.service.models.NotificationParams
import com.google.gson.Gson
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

enum class RunState {
    START, PENDING, STOP
}


object State {

    val runLock = Mutex()

    var runTime: Long = 0

    var sharedState: SharedState = SharedState()

    val runStateFlow: MutableStateFlow<RunState> = MutableStateFlow(RunState.STOP)

    var flutterEngine: FlutterEngine? = null

    val tilePlugin: TilePlugin?
        get() = flutterEngine?.plugin<TilePlugin>()

    suspend fun handleToggleAction() {
        var action: (suspend () -> Unit)?
        runLock.withLock {
            action = when (runStateFlow.value) {
                RunState.PENDING -> null
                RunState.START -> ::handleStopServiceAction
                RunState.STOP -> ::handleStartServiceAction
            }
        }
        action?.invoke()
    }

    suspend fun handleSyncState() {
        runLock.withLock {
            try {
                if (RootModule.isRunning()) {
                    if (runTime == 0L) {
                        runTime = System.currentTimeMillis()
                    }
                    runStateFlow.tryEmit(RunState.START)
                    return
                }
                runTime = 0L
                runStateFlow.tryEmit(RunState.STOP)
            } catch (_: Exception) {
                runTime = 0L
                runStateFlow.tryEmit(RunState.STOP)
            }
        }
    }

    suspend fun handleStartServiceAction() {
        runLock.withLock {
            if (runStateFlow.value != RunState.STOP) {
                return
            }
            tilePlugin?.handleStart()
            if (flutterEngine != null) {
                return
            }
            startServiceWithPref()
        }

    }

    suspend fun handleStopServiceAction() {
        runLock.withLock {
            if (runStateFlow.value != RunState.START) {
                return
            }
            tilePlugin?.handleStop()
            if (flutterEngine != null) {
                return
            }
            GlobalState.application.showToast(sharedState.stopTip)
            handleStopService()
        }
    }

    fun handleStartService() {
        GlobalState.launch {
            startService()
        }
    }

    suspend fun handleStartServiceAndWait(): Boolean = startService()

    private fun startServiceWithPref() {
        GlobalState.launch {
            runLock.withLock {
                if (runStateFlow.value != RunState.STOP) {
                    return@launch
                }
                sharedState = GlobalState.application.sharedState
                setupAndStart()
            }
        }
    }

    suspend fun syncState() {
        GlobalState.setCrashlytics(sharedState.crashlytics)
        Service.updateNotificationParams(
            NotificationParams(
                title = sharedState.currentProfileName,
                stopText = sharedState.stopText,
                onlyStatisticsProxy = sharedState.onlyStatisticsProxy
            )
        )
        Service.setCrashlytics(sharedState.crashlytics)
    }

    private suspend fun setupAndStart() {
        Service.bind()
        syncState()
        GlobalState.application.showToast(sharedState.startTip)
        val initParams = mutableMapOf<String, Any>()
        initParams["home-dir"] = GlobalState.application.filesDir.path
        initParams["version"] = android.os.Build.VERSION.SDK_INT
        val initParamsString = Gson().toJson(initParams)
        val setupParamsString = Gson().toJson(sharedState.setupParams)
        Service.quickSetup(
            initParamsString,
            setupParamsString,
            onStarted = {
                GlobalState.launch {
                    startService()
                }
            },
            onResult = {
                if (it.isNotEmpty()) {
                    GlobalState.application.showToast(it)
                }
            },
        )
    }

    private suspend fun startService(): Boolean {
        return runLock.withLock {
            if (RootModule.isRunning()) {
                if (runTime == 0L) {
                    runTime = System.currentTimeMillis()
                }
                runStateFlow.tryEmit(RunState.START)
                return@withLock true
            }
            if (runStateFlow.value != RunState.STOP) {
                return@withLock runStateFlow.value == RunState.START
            }
            try {
                runStateFlow.tryEmit(RunState.PENDING)
                val started = RootModule.start()
                if (started || RootModule.isRunning()) {
                    runTime = when (runTime != 0L) {
                        true -> runTime
                        false -> System.currentTimeMillis()
                    }
                    runStateFlow.tryEmit(RunState.START)
                    return@withLock true
                }
                GlobalState.application.showToast(
                    "Conceal FlClash TUN Helper start failed"
                )
                false
            } finally {
                if (runStateFlow.value == RunState.PENDING) {
                    runStateFlow.tryEmit(RunState.STOP)
                }
            }
        }
    }

    fun handleStopService() {
        GlobalState.launch {
            stopService()
        }
    }

    suspend fun handleStopServiceAndWait(): Boolean = stopService()

    private suspend fun stopService(): Boolean {
        return runLock.withLock {
            if (runStateFlow.value != RunState.START && !RootModule.isRunning()) {
                return@withLock runStateFlow.value == RunState.STOP
            }
            try {
                runStateFlow.tryEmit(RunState.PENDING)
                RootModule.stop()
                if (RootModule.isRunning()) {
                    if (runTime == 0L) {
                        runTime = System.currentTimeMillis()
                    }
                    runStateFlow.tryEmit(RunState.START)
                    false
                } else {
                    runTime = 0L
                    runStateFlow.tryEmit(RunState.STOP)
                    true
                }
            } finally {
                if (runStateFlow.value == RunState.PENDING) {
                    runStateFlow.tryEmit(RunState.START)
                }
            }
        }
    }
}
