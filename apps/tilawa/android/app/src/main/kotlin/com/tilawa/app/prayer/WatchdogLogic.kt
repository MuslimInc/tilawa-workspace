package com.tilawa.app.prayer

import androidx.work.ListenableWorker.Result

internal class WatchdogLogic {
    fun handleComplete(
        success: Boolean?,
        retryable: Boolean?,
        message: String?,
        action: String?
    ): Result {
        return WatchdogResultMapper.map(
            success ?: false,
            retryable ?: false
        )
    }
}
