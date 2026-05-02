package com.tilawa.app.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.core.content.edit

/**
 * Schedules and cancels Adhan playback alarms via [AlarmManager.setAlarmClock].
 *
 * `setAlarmClock` is the highest-priority class of alarm — it bypasses Doze
 * mode, App Standby, and battery optimisation throttling, which is the
 * behavioural guarantee we need for prayer reminders.
 *
 * Each alarm targets [AdhanReceiver] and carries the prayer name + scheduled
 * epoch millis as extras. We persist the active set of alarm IDs so the same
 * scheduler instance can cancel them later without enumerating every possible
 * notification ID.
 */
internal object AdhanScheduler {
    const val EXTRA_PRAYER_NAME = "prayer_name"
    const val EXTRA_PRAYER_KEY = "prayer_key"
    const val EXTRA_NOTIFICATION_ID = "notification_id"
    const val EXTRA_SCHEDULED_MS = "scheduled_ms"
    const val EXTRA_SOUND = "sound"

    private var storage: PrayerStorage? = null
    private var alarmManager: PrayerAlarmManager? = null

    private fun getStorage(context: Context): PrayerStorage =
        storage ?: DefaultPrayerStorage(context).also { storage = it }

    private fun getAlarmManager(context: Context): PrayerAlarmManager =
        alarmManager ?: DefaultPrayerAlarmManager(context).also { alarmManager = it }

    @VisibleForTesting
    fun setDependencies(storage: PrayerStorage?, alarmManager: PrayerAlarmManager?) {
        this.storage = storage
        this.alarmManager = alarmManager
    }

    fun canScheduleExact(context: Context): Boolean {
        return getAlarmManager(context).canScheduleExact()
    }

    fun schedule(
        context: Context,
        notificationId: Int,
        prayerName: String,
        prayerKey: String,
        triggerAtMillis: Long,
    ): Boolean {
        val am = getAlarmManager(context)
        val st = getStorage(context)

        if (!am.canScheduleExact()) {
            return false
        }

        // Derive sound name: adhan_fajr for Fajr, else adhan
        val sound = if (prayerKey.lowercase() == "fajr") "adhan_fajr" else "adhan"

        if (am.scheduleExact(notificationId, prayerName, prayerKey, triggerAtMillis, sound)) {
            st.addActiveId(notificationId)
            return true
        }
        return false
    }

    // Overload for manual sound specification (e.g. from boot re-arm)
    fun schedule(
        context: Context,
        notificationId: Int,
        prayerName: String,
        prayerKey: String,
        triggerAtMillis: Long,
        sound: String,
    ): Boolean {
        val am = getAlarmManager(context)
        val st = getStorage(context)

        if (!am.canScheduleExact()) {
            return false
        }

        if (am.scheduleExact(notificationId, prayerName, prayerKey, triggerAtMillis, sound)) {
            st.addActiveId(notificationId)
            return true
        }
        return false
    }

    fun cancel(context: Context, notificationId: Int) {
        getAlarmManager(context).cancel(notificationId)
        getStorage(context).removeActiveId(notificationId)
    }

    fun cancelAll(context: Context) {
        val am = getAlarmManager(context)
        val st = getStorage(context)
        
        am.cancelAll(st.getActiveIds())
        st.clearActiveIds()
        st.setPendingAlarmsJson(null)
    }
}

/**
 * Annotation to mark methods visible for testing only.
 */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.PROPERTY_GETTER, AnnotationTarget.PROPERTY_SETTER)
@Retention(AnnotationRetention.BINARY)
internal annotation class VisibleForTesting
