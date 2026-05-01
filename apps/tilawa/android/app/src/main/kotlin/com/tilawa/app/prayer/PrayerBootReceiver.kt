package com.tilawa.app.prayer

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject

/**
 * Re-arms prayer-time alarms after events that wipe or skew the AlarmManager
 * schedule (reboot, app update, time/timezone change).
 *
 * Strategy: every successful Dart-side schedule pass persists the next 14 days
 * of (id, prayerName, triggerMs) tuples to SharedPreferences. After boot, this
 * receiver re-installs `setAlarmClock` entries whose trigger time is still in
 * the future — without bringing up Flutter at boot. The next app launch (or
 * the WorkManager watchdog the Dart side schedules at startup) performs a
 * full Dart reschedule and refreshes the persisted list.
 */
internal class PrayerBootReceiver : BroadcastReceiver() {
    companion object {
        const val PREFS_NAME = "prayer_adhan_alarms"
        const val PREF_KEY_PENDING_ALARMS = "pending_alarms_json"
        const val PREF_KEY_NEEDS_RESCHEDULE = "needs_reschedule_after_boot"

        private const val FIELD_ID = "id"
        private const val FIELD_NAME = "name"
        private const val FIELD_TRIGGER_MS = "trigger"

        @JvmStatic
        fun persistPendingAlarms(
            context: Context,
            entries: List<Triple<Int, String, Long>>,
        ) {
            val arr = JSONArray()
            entries.forEach {
                arr.put(
                    JSONObject().apply {
                        put(FIELD_ID, it.first)
                        put(FIELD_NAME, it.second)
                        put(FIELD_TRIGGER_MS, it.third)
                    },
                )
            }
            DefaultPrayerStorage(context).setPendingAlarmsJson(arr.toString())
        }

        @JvmStatic
        fun clearPendingAlarms(context: Context) {
            DefaultPrayerStorage(context).setPendingAlarmsJson(null)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                val analytics = FirebasePrayerAnalytics(context)
                analytics.logEvent(PrayerEvents.BOOT_TRIGGERED, mapOf(
                    "action" to intent.action,
                    "uptime_millis" to android.os.SystemClock.elapsedRealtime()
                ))
                reArmAlarms(context)
            }
            else -> Unit
        }
    }

    private fun reArmAlarms(context: Context) {
        val storage = DefaultPrayerStorage(context)
        val analytics = FirebasePrayerAnalytics(context)
        val logic = BootLogic(
            storage = storage,
            scheduler = object : AdhanSchedulerProxy {
                override fun canScheduleExact() = AdhanScheduler.canScheduleExact(context)
                override fun areNotificationsEnabled(): Boolean {
                    val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    return nm.areNotificationsEnabled()
                }
                override fun schedule(id: Int, name: String, triggerMs: Long) =
                    AdhanScheduler.schedule(context, id, name, triggerMs)
            },
            watchdog = object : WatchdogProxy {
                override fun enqueuePeriodic() =
                    PrayerNotificationsWatchdogScheduler.enqueuePeriodic(context)
                override fun enqueueOneTime() =
                    PrayerNotificationsWatchdogScheduler.enqueueOneTime(context)
            },
            analytics = analytics
        )
        logic.reArmAlarms(System.currentTimeMillis())
    }
}
