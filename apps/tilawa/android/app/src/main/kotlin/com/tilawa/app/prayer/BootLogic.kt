package com.tilawa.app.prayer

import android.content.Context
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

internal class BootLogic(
    private val storage: PrayerStorage,
    private val scheduler: AdhanSchedulerProxy,
    private val watchdog: WatchdogProxy,
    private val analytics: PrayerAnalytics? = null
) {
    fun reArmAlarms(now: Long) {
        storage.setNeedsReschedule(true)
        watchdog.enqueuePeriodic()
        watchdog.enqueueOneTime()

        val raw = storage.getPendingAlarmsJson() ?: return
        val pending = try {
            val arr = JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    add(
                        AlarmEntry(
                            obj.getInt("id"),
                            obj.optString("name", ""),
                            obj.getLong("trigger"),
                            obj.optString("sound", "adhan")
                        )
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
                    "fallback_used" to false
                )
            )
            emptyList()
        }

        if (pending.isEmpty()) return

        for (entry in pending) {
            if (entry.trigger <= now) continue
            try {
                val ok = scheduler.schedule(entry.id, entry.name, entry.trigger, entry.sound)
                if (ok) {
                    analytics?.logEvent(PrayerEvents.SCHEDULE_SUCCESS, mapOf(
                        "prayer_name" to entry.name,
                        "context" to "boot_rearm"
                    ))
                } else {
                    analytics?.logEvent(PrayerEvents.SCHEDULE_FAILED, mapOf(
                        "prayer_name" to entry.name,
                        "context" to "boot_rearm",
                        "reason" to "permission_denied"
                    ))
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
                        "fallback_used" to false
                    )
                )
            }
        }
    }

    private data class AlarmEntry(
        val id: Int,
        val name: String,
        val trigger: Long,
        val sound: String
    )
}

interface AdhanSchedulerProxy {
    fun canScheduleExact(): Boolean
    fun areNotificationsEnabled(): Boolean
    fun schedule(id: Int, name: String, triggerMs: Long, sound: String): Boolean
}

interface WatchdogProxy {
    fun enqueuePeriodic()
    fun enqueueOneTime()
}
