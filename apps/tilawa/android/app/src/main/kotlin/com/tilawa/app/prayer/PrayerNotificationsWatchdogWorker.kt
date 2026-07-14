package com.tilawa.app.prayer

import android.app.NotificationManager
import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * Periodic / one-shot WorkManager job that keeps AlarmManager prayer clocks
 * alive when the app is not opened for a while.
 *
 * **Native-only:** re-arms from the persisted DPS pending-alarms JSON via
 * [BootLogic.reArmPendingAlarmsForWatchdog]. A previous implementation spun a
 * headless [io.flutter.embedding.engine.FlutterEngine] on the main looper from
 * this worker; that blocked input dispatch and surfaced as Play / Sentry
 * Background ANRs at `android.os.MessageQueue.nativePollOnce` (e.g. FLUTTER-W).
 *
 * Full Dart schedule refresh still happens on the next app open through
 * `needs_reschedule_after_boot` (consumed via the adhan method channel).
 */
internal class PrayerNotificationsWatchdogWorker(
    appContext: Context,
    workerParams: WorkerParameters,
) : Worker(appContext, workerParams) {
    override fun doWork(): Result {
        val analytics = FirebasePrayerAnalytics(applicationContext)
        analytics.logEvent(PrayerEvents.WATCHDOG_TRIGGERED)
        Log.d(TAG, "Prayer notification watchdog started (native re-arm)")

        val nm =
            applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (!nm.areNotificationsEnabled()) {
            Log.i(TAG, "Notification permission revoked, canceling all native alarms")
            AdhanScheduler.cancelAll(applicationContext)
            analytics.logEvent(
                PrayerEvents.WATCHDOG_COMPLETED,
                mapOf("action" to "cancel_all_notifications_disabled"),
            )
            return Result.success()
        }

        return try {
            val storage = DefaultPrayerStorage(applicationContext)
            val logic = BootLogic(
                storage = storage,
                scheduler = object : AdhanSchedulerProxy {
                    override fun getContext() = applicationContext
                    override fun canScheduleExact() =
                        AdhanScheduler.canScheduleExact(applicationContext)

                    override fun areNotificationsEnabled(): Boolean = nm.areNotificationsEnabled()

                    override fun schedule(
                        id: Int,
                        name: String,
                        key: String,
                        triggerMs: Long,
                        sound: String,
                        locationName: String,
                        languageCode: String,
                    ) = AdhanScheduler.schedule(
                        applicationContext,
                        id,
                        name,
                        key,
                        triggerMs,
                        sound,
                        locationName,
                        languageCode,
                    )
                },
                // Already inside the worker — do not enqueue another run.
                watchdog = object : WatchdogProxy {
                    override fun enqueuePeriodic() = Unit
                    override fun enqueueOneTime() = Unit
                },
                analytics = analytics,
            )

            val scheduled = logic.reArmPendingAlarmsForWatchdog(System.currentTimeMillis())
            Log.d(TAG, "Native watchdog re-armed count=$scheduled")
            analytics.logEvent(
                PrayerEvents.WATCHDOG_COMPLETED,
                mapOf(
                    "action" to "native_rearm",
                    "scheduled_count" to scheduled,
                ),
            )
            Result.success()
        } catch (t: Throwable) {
            Log.e(TAG, "Native prayer watchdog failed", t)
            analytics.logError(
                "Native prayer watchdog failed",
                t,
                mapOf(
                    "exact_alarm_permission_granted" to
                        AdhanScheduler.canScheduleExact(applicationContext),
                    "notification_permission_granted" to nm.areNotificationsEnabled(),
                    "device_manufacturer" to android.os.Build.MANUFACTURER,
                    "fallback_used" to false,
                ),
            )
            analytics.logEvent(
                PrayerEvents.WATCHDOG_FAILED,
                mapOf("reason" to "native_rearm_error"),
            )
            Result.retry()
        }
    }

    companion object {
        private const val TAG = "PrayerWatchdog"
    }
}
