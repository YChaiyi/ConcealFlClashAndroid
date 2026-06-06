package com.follow.clash.models

import com.follow.clash.service.models.VpnOptions
import com.google.gson.annotations.SerializedName

data class SharedState(
    val startTip: String = "Starting TUN proxy...",
    val stopTip: String = "Stopping TUN proxy...",
    val crashlytics: Boolean = true,
    val currentProfileName: String = "Conceal FlClash Android",
    val stopText: String = "Stop",
    val onlyStatisticsProxy: Boolean = false,
    val vpnOptions: VpnOptions? = null,
    val setupParams: SetupParams? = null,
)

data class SetupParams(
    @SerializedName("test-url")
    val testUrl: String,
    @SerializedName("selected-map")
    val selectedMap: Map<String, String>,
)
