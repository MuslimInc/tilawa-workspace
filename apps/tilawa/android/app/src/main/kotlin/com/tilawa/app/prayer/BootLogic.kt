package com.tilawa.app.prayer

import android.content.Context
import android.util.Log
import org.json.JSONArray

internal class BootLogic(
    private val storage: PrayerStorage,
    private val scheduler: AdhanSchedulerProxy,
    private val watchdog: WatchdogProxy,
    private val analytics: PrayerAnalytics? = null,
) {
    private fun logDebug(message: String) {
        try {
            val ctx = scheduler.getContext()
            val isDebuggable =
                (ctx.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
            if (isDebuggable) Log.d("PrayerBootReceiver", message)
        } catch (_: Throwable) {
        }
    }

    /**
     * Boot / package-replace path: mark Dart for a full refresh, keep the
     * WorkManager watchdog armed, then re-install future AlarmManager clocks
     * from the persisted DPS JSON (no Flutter).
     */
    fun reArmAlarms(now: Long) {
        storage.setNeedsReschedule(true)
        watchdog.enqueuePeriodic()
        watchdog.enqueueOneTime()
        reArmPendingAlarms(now, contextLabel = "boot_rearm")
    }

    /**
     * Native-only re-arm used by [PrayerNotificationsWatchdogWorker].
     *
     * Does **not** spin a FlutterEngine (that wedges the Android main looper
     * and shows up as `MessageQueue.nativePollOnce` / Background ANR). Leaves
     * [PrayerStorage.setNeedsReschedule] so the next app open runs a full Dart
     * ensure-scheduled pass.
     *
     * @return number of future alarms successfully handed to the scheduler
     */
    fun reArmPendingAlarmsForWatchdog(now: Long): Int {
        storage.setNeedsReschedule(true)
        return reArmPendingAlarms(now, contextLabel = "watchdog_rearm")
    }

    private fun reArmPendingAlarms(now: Long, contextLabel: String): Int {
        val raw = storage.getPendingAlarmsJson() ?: return 0
        val pending = try {
            val arr = JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    val name = obj.optString("name", "")
                    val key = obj.optString("key", name.lowercase())
                    add(
                        AlarmEntry(
                            obj.getInt("id"),
                            name,
                            key,
                            obj.getLong("trigger"),
                            obj.optString("sound", "adhan"),
                            obj.optString("location", ""),
                            obj.optString("language", ""),
                        ),
                    )
                }
            }
        } catch (t: Throwable) {
            analytics?.logError(
                "Failed to parse pending alarms JSON",
                t,
                mapOf(
                    "exact_alarm_permission_granted" to scheduler.canScheduleExact(),
                    "notification_permission_granted" to scheduler.areNotificationsEnabled(),
                    "device_manufacturer" to android.os.Build.MANUFACTURER,
                    "fallback_used" to false,
                ),
            )
            emptyList()
        }

        if (pending.isEmpty()) return 0

        var scheduled = 0
        for (entry in pending) {
            if (entry.trigger <= now) continue
            try {
                logDebug(
                    "ADHAN_AUDIT source=$contextLabel event=attempt prayerKey=${entry.key} " +
                        "prayerName=${entry.name} scheduledMs=${entry.trigger} " +
                        "notificationId=${entry.id} requestCode=${entry.id}",
                )
                val ok = scheduler.schedule(
                    entry.id,
                    entry.name,
                    entry.key,
                    entry.trigger,
                    entry.sound,
                    entry.locationName,
                    entry.languageCode,
                )
                if (ok) {
                    scheduled += 1
                    analytics?.logEvent(
                        PrayerEvents.SCHEDULE_SUCCESS,
                        mapOf(
                            "prayer_name" to entry.name,
                            "context" to contextLabel,
                        ),
                    )
                } else {
                    analytics?.logEvent(
                        PrayerEvents.SCHEDULE_FAILED,
                        mapOf(
                            "prayer_name" to entry.name,
                            "context" to contextLabel,
                            "reason" to "permission_denied",
                        ),
                    )
                }
            } catch (t: Throwable) {
                analytics?.logError(
                    "Failed to schedule alarm during boot re-arm",
                    t,
                    mapOf(
                        "prayer_name" to entry.name,
                        "exact_alarm_permission_granted" to scheduler.canScheduleExact(),
                        "notification_permission_granted" to scheduler.areNotificationsEnabled(),
                        "device_manufacturer" to android.os.Build.MANUFACTURER,
                        "fallback_used" to false,
                    ),
                )
            }
        }
        return scheduled
    }

    private data class AlarmEntry(
        val id: Int,
        val name: String,
        val key: String,
        val trigger: Long,
        val sound: String,
        val locationName: String,
        val languageCode: String,
    )
}

interface AdhanSchedulerProxy {
    fun getContext(): Context
    fun canScheduleExact(): Boolean
    fun areNotificationsEnabled(): Boolean
    fun schedule(
        id: Int,
        name: String,
        key: String,
        triggerMs: Long,
        sound: String,
        locationName: String = "",
        languageCode: String = "",
    ): Boolean
}

interface WatchdogProxy {
    fun enqueuePeriodic()
    fun enqueueOneTime()
}
