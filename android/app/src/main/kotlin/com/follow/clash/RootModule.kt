package com.follow.clash

import com.follow.clash.common.GlobalState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.io.File

object RootModule {
    private const val START_TIMEOUT_MS = 70_000L
    private const val STOP_TIMEOUT_MS = 15_000L
    private const val POLL_INTERVAL_MS = 500L

    private val controlDir: File
        get() = File(GlobalState.application.filesDir, "root-module")

    private val requestFile: File
        get() = File(controlDir, "request")

    private val statusFile: File
        get() = File(controlDir, "status")

    suspend fun start(): Boolean {
        writeRequest("start")
        return waitForRunning(true, START_TIMEOUT_MS)
    }

    suspend fun stop(): Boolean {
        writeRequest("stop")
        return waitForRunning(false, STOP_TIMEOUT_MS)
    }

    suspend fun isRunning(): Boolean {
        return readRunningStatus() == true
    }

    private suspend fun writeRequest(action: String) = withContext(Dispatchers.IO) {
        runCatching {
            controlDir.mkdirs()
            statusFile.delete()
            val tempRequestFile = File(controlDir, "request.tmp")
            tempRequestFile.writeText(action)
            if (requestFile.exists()) {
                requestFile.delete()
            }
            tempRequestFile.renameTo(requestFile)
            requestFile.setReadable(true, false)
            requestFile.setWritable(true, false)
            controlDir.setReadable(true, false)
            controlDir.setWritable(true, false)
            controlDir.setExecutable(true, false)
            GlobalState.log("Root module request=$action")
        }.onFailure {
            GlobalState.log("Root module request $action failed: $it")
        }
    }

    private suspend fun waitForRunning(
        expectedRunning: Boolean,
        timeoutMs: Long,
    ): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            val running = readRunningStatus()
            if (running == expectedRunning) {
                return true
            }
            delay(POLL_INTERVAL_MS)
        }
        val running = readRunningStatus()
        GlobalState.log(
            "Root module wait expected=$expectedRunning timed out, actual=$running"
        )
        return running == expectedRunning
    }

    private suspend fun readRunningStatus(): Boolean? = withContext(Dispatchers.IO) {
        runCatching {
            val value = statusFile.readText().trim()
            GlobalState.log("Root module status=$value")
            when (value) {
                "running" -> true
                "stopped" -> false
                else -> null
            }
        }.getOrElse {
            GlobalState.log("Root module status unavailable: $it")
            null
        }
    }
}
