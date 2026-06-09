package com.follow.clash

import com.follow.clash.common.GlobalState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.TimeUnit

object RootModule {
    private const val START_TIMEOUT_MS = 70_000L
    private const val STOP_TIMEOUT_MS = 15_000L
    private const val REQUEST_CONSUME_TIMEOUT_MS = 6_000L
    private const val POLL_INTERVAL_MS = 500L
    private const val MODULE_SCRIPT =
        "/data/adb/modules/conceal-flclash-tun-helper/scripts/flclash-root.sh"

    private val controlDir: File
        get() = File(GlobalState.application.filesDir, "root-module")

    private val requestFile: File
        get() = File(controlDir, "request")

    private val statusFile: File
        get() = File(controlDir, "status")

    suspend fun start(): Boolean {
        writeRequest("start")
        if (waitForRunning(true, REQUEST_CONSUME_TIMEOUT_MS)) {
            return true
        }
        if (requestFile.exists()) {
            deleteRequest()
            GlobalState.log("Root module start request was not consumed; trying su fallback")
            return runModuleCommand("start", START_TIMEOUT_MS) &&
                    waitForRunning(true, REQUEST_CONSUME_TIMEOUT_MS)
        }
        if (waitForRunning(true, START_TIMEOUT_MS - REQUEST_CONSUME_TIMEOUT_MS)) {
            return true
        }
        GlobalState.log("Root module start request timed out; trying su fallback")
        return runModuleCommand("start", START_TIMEOUT_MS) &&
                waitForRunning(true, REQUEST_CONSUME_TIMEOUT_MS)
    }

    suspend fun stop(): Boolean {
        writeRequest("stop")
        if (waitForRunning(false, REQUEST_CONSUME_TIMEOUT_MS)) {
            return true
        }
        if (requestFile.exists()) {
            deleteRequest()
            GlobalState.log("Root module stop request was not consumed; trying su fallback")
            return runModuleCommand("stop", STOP_TIMEOUT_MS) &&
                    waitForRunning(false, REQUEST_CONSUME_TIMEOUT_MS)
        }
        if (waitForRunning(false, STOP_TIMEOUT_MS)) {
            return true
        }
        GlobalState.log("Root module stop request timed out; trying su fallback")
        return runModuleCommand("stop", STOP_TIMEOUT_MS) &&
                waitForRunning(false, REQUEST_CONSUME_TIMEOUT_MS)
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

    private suspend fun deleteRequest() = withContext(Dispatchers.IO) {
        runCatching {
            requestFile.delete()
        }
    }

    private suspend fun runModuleCommand(
        action: String,
        timeoutMs: Long,
    ): Boolean = withContext(Dispatchers.IO) {
        runCatching {
            if (!File(MODULE_SCRIPT).exists()) {
                GlobalState.log("Root module script is missing: $MODULE_SCRIPT")
                return@withContext false
            }
            val process = ProcessBuilder("su", "-c", "$MODULE_SCRIPT $action")
                .redirectErrorStream(true)
                .start()
            val completed = process.waitFor(timeoutMs, TimeUnit.MILLISECONDS)
            if (!completed) {
                process.destroyForcibly()
                GlobalState.log("Root module su $action timed out")
                return@withContext false
            }
            val output = process.inputStream.bufferedReader().readText().trim()
            val exitCode = process.exitValue()
            GlobalState.log("Root module su $action exit=$exitCode output=$output")
            exitCode == 0
        }.getOrElse {
            GlobalState.log("Root module su $action failed: $it")
            false
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
