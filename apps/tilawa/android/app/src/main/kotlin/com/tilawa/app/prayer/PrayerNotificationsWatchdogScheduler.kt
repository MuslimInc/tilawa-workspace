package com.tilawa.app.prayer

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

interface WorkManagerProxy {
    fun enqueuePeriodic(context: Context)
    fun enqueueOneTime(context: Context)
}

internal object DefaultWorkManagerProxy : WorkManagerProxy {
    private const val TAG = "PrayerWatchdog"
    private const val PERIODIC_WORK_NAME = "prayer_notifications_watchdog_periodic"
    private const val ONE_TIME_WORK_NAME = "prayer_notifications_watchdog_one_time"

    override fun enqueuePeriodic(context: Context) {
        val workManager = WorkManager.getInstance(context)
        val request = PeriodicWorkRequestBuilder<PrayerNotificationsWatchdogWorker>(
            12,
            TimeUnit.HOURS,
        )
            .setConstraints(periodicConstraints())
            .addTag(TAG)
            .build()

        workManager.enqueueUniquePeriodicWork(
            PERIODIC_WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
        Log.d(TAG, "Periodic prayer notification watchdog enqueued")
    }

    override fun enqueueOneTime(context: Context) {
        val workManager = WorkManager.getInstance(context)
        val request = OneTimeWorkRequestBuilder<PrayerNotificationsWatchdogWorker>()
            .addTag(TAG)
            .build()

        workManager.enqueueUniqueWork(
            ONE_TIME_WORK_NAME,
            ExistingWorkPolicy.REPLACE,
            request,
        )
        Log.d(TAG, "One-time prayer notification watchdog enqueued")
    }

    private fun periodicConstraints(): Constraints =
        Constraints.Builder()
            .setRequiresBatteryNotLow(true)
            .build()
}

internal object PrayerNotificationsWatchdogScheduler {
    private var proxy: WorkManagerProxy? = null

    @VisibleForTesting
    fun setProxy(proxy: WorkManagerProxy?) {
        this.proxy = proxy
    }

    private fun getProxy(): WorkManagerProxy =
        proxy ?: DefaultWorkManagerProxy

    fun enqueuePeriodic(context: Context) {
        getProxy().enqueuePeriodic(context)
    }

    fun enqueueOneTime(context: Context) {
        getProxy().enqueueOneTime(context)
    }
}
