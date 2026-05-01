package com.tilawa.app.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import androidx.core.content.edit

class DefaultPrayerStorage(private val context: Context) : PrayerStorage {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("prayer_adhan_alarms", Context.MODE_PRIVATE)

    override fun getActiveIds(): Set<Int> {
        val raw = prefs.getStringSet("active_ids", emptySet()) ?: emptySet()
        return raw.mapNotNull { it.toIntOrNull() }.toSet()
    }

    override fun addActiveId(id: Int) {
        val ids = getActiveIds().toMutableSet()
        ids.add(id)
        prefs.edit { putStringSet("active_ids", ids.map { it.toString() }.toSet()) }
    }

    override fun removeActiveId(id: Int) {
        val ids = getActiveIds().toMutableSet()
        if (ids.remove(id)) {
            prefs.edit { putStringSet("active_ids", ids.map { it.toString() }.toSet()) }
        }
    }

    override fun clearActiveIds() {
        prefs.edit { remove("active_ids") }
    }

    override fun getPendingAlarmsJson(): String? =
        prefs.getString("pending_alarms_json", null)

    override fun setPendingAlarmsJson(json: String?) {
        prefs.edit {
            if (json == null) remove("pending_alarms_json")
            else putString("pending_alarms_json", json)
        }
    }

    override fun setNeedsReschedule(needs: Boolean) {
        prefs.edit { putBoolean("needs_reschedule_after_boot", needs) }
    }

    override fun needsReschedule(): Boolean =
        prefs.getBoolean("needs_reschedule_after_boot", false)
}

class DefaultPrayerAlarmManager(private val context: Context) : PrayerAlarmManager {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    override fun scheduleExact(id: Int, name: String, triggerMs: Long): Boolean {
        if (!canScheduleExact()) return false
        
        val pi = pendingIntent(id, name, triggerMs)
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
            pi
        )
        return true
    }

    override fun cancel(id: Int) {
        alarmManager.cancel(pendingIntent(id, "", 0L))
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
        triggerAtMillis: Long,
    ): PendingIntent {
        val intent = Intent(context, AdhanReceiver::class.java).apply {
            action = "com.tilawa.app.prayer.ACTION_FIRE_ADHAN"
            putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, triggerAtMillis)
        }
        return PendingIntent.getBroadcast(context, notificationId, intent, piFlags())
    }

    private fun piFlags(): Int =
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
}
