package com.tilawa.app.prayer

import androidx.work.ListenableWorker.Result

internal object WatchdogResultMapper {
    fun map(success: Boolean, retryable: Boolean): Result {
        return when {
            success -> Result.success()
            retryable -> Result.retry()
            else -> Result.failure()
        }
    }
}
