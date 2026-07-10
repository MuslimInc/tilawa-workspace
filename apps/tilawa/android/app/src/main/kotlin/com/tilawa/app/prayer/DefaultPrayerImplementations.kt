package com.tilawa.app.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.core.content.edit

class DefaultPrayerStorage(private val context: Context) : PrayerStorage {
    // Standard CPS storage for full runtime state
    private val cpsPrefs: SharedPreferences =
        context.getSharedPreferences("prayer_adhan_alarms", Context.MODE_PRIVATE)

    // Minimal DPS storage for boot re-arming
    private val dpsPrefs: SharedPreferences by lazy {
        val protectedContext = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.createDeviceProtectedStorageContext()
        } else {
            context
        }
        protectedContext.getSharedPreferences("prayer_adhan_boot", Context.MODE_PRIVATE)
    }

    override fun getActiveIds(): Set<Int> {
        val raw = cpsPrefs.getStringSet("active_ids", emptySet()) ?: emptySet()
        return raw.mapNotNull { it.toIntOrNull() }.toSet()
    }

    override fun addActiveId(id: Int) {
        val ids = getActiveIds().toMutableSet()
        ids.add(id)
        cpsPrefs.edit { putStringSet("active_ids", ids.map { it.toString() }.toSet()) }
    }

    override fun removeActiveId(id: Int) {
        val ids = getActiveIds().toMutableSet()
        if (ids.remove(id)) {
            cpsPrefs.edit { putStringSet("active_ids", ids.map { it.toString() }.toSet()) }
        }
    }

    override fun clearActiveIds() {
        cpsPrefs.edit { remove("active_ids") }
    }

    override fun getPendingAlarmsJson(): String? = dpsPrefs.getString("pending_alarms_json", null)

    override fun setPendingAlarmsJson(json: String?) {
        dpsPrefs.edit {
            if (json == null) remove("pending_alarms_json")
            else putString("pending_alarms_json", json)
        }
        // Cleanup CPS key if it exists
        if (cpsPrefs.contains("pending_alarms_json")) {
            cpsPrefs.edit { remove("pending_alarms_json") }
        }
    }

    override fun setNeedsReschedule(needs: Boolean) {
        dpsPrefs.edit { putBoolean("needs_reschedule_after_boot", needs) }
    }

    override fun needsReschedule(): Boolean =
        dpsPrefs.getBoolean("needs_reschedule_after_boot", false)

    override fun setLastNotificationLocationName(name: String?) {
        cpsPrefs.edit {
            if (name.isNullOrBlank()) remove("last_notification_location_name")
            else putString("last_notification_location_name", name)
        }
    }

    override fun getLastNotificationLocationName(): String? =
        cpsPrefs.getString("last_notification_location_name", null)
}

class DefaultPrayerAlarmManager(private val context: Context) : PrayerAlarmManager {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val isDebuggable: Boolean =
        (context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0

    private fun logDebug(message: String) {
        if (isDebuggable) Log.d("AdhanScheduler", message)
    }

    override fun scheduleExact(
        id: Int,
        name: String,
        key: String,
        triggerMs: Long,
        sound: String,
        locationName: String,
        languageCode: String,
    ): Boolean {
        if (!canScheduleExact()) return false

        val pi = pendingIntent(id, name, key, triggerMs, sound, locationName, languageCode)
        val showIntent = PendingIntent.getActivity(
            context,
            id,
            Intent(context, Class.forName("com.tilawa.app.MainActivity")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            piFlags(),
        )

        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(triggerMs, showIntent),
            pi,
        )
        logDebug(
            "ADHAN_AUDIT source=alarm_scheduler event=schedule prayerKey=$key prayerName=$name " +
                "scheduledMs=$triggerMs notificationId=$id requestCode=$id sound=$sound"
        )
        return true
    }

    override fun scheduleInexact(
        id: Int,
        name: String,
        key: String,
        triggerMs: Long,
        sound: String,
        locationName: String,
        languageCode: String,
    ): Boolean {
        val pi = pendingIntent(id, name, key, triggerMs, sound, locationName, languageCode)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerMs, pi)
        }
        logDebug(
            "ADHAN_AUDIT source=alarm_scheduler event=schedule_inexact prayerKey=$key prayerName=$name " +
                "scheduledMs=$triggerMs notificationId=$id requestCode=$id sound=$sound"
        )
        return true
    }

    override fun cancel(id: Int) {
        logDebug(
            "ADHAN_AUDIT source=alarm_scheduler event=cancel notificationId=$id requestCode=$id"
        )
        alarmManager.cancel(pendingIntent(id, "", "", 0L, "adhan"))
    }

    override fun cancelAll(ids: Set<Int>) {
        for (id in ids) {
            cancel(id)
        }
    }

    override fun canScheduleExact(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun pendingIntent(
        notificationId: Int,
        prayerName: String,
        prayerKey: String,
        triggerAtMillis: Long,
        sound: String,
        locationName: String = "",
        languageCode: String = "",
    ): PendingIntent {
        val intent = Intent(context, AdhanReceiver::class.java).apply {
            action = "com.tilawa.app.prayer.ACTION_FIRE_ADHAN"
            putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, prayerKey)
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, triggerAtMillis)
            putExtra(AdhanScheduler.EXTRA_SOUND, sound)
            if (locationName.isNotBlank()) {
                putExtra(AdhanScheduler.EXTRA_LOCATION_NAME, locationName)
            }
            if (languageCode.isNotBlank()) {
                putExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE, languageCode)
            }
        }
        return PendingIntent.getBroadcast(context, notificationId, intent, piFlags())
    }

    private fun piFlags(): Int =
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
}
