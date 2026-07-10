package com.tilawa.app.prayer

import android.app.AlarmManager
import android.content.Context

/**
 * Schedules and cancels Adhan playback alarms via [AlarmManager].
 *
 * `setAlarmClock` is the preferred path because it bypasses Doze mode, App
 * Standby, and battery optimisation throttling. If the user has not granted
 * Android 12+ exact alarm access, we keep the alarm native with an inexact
 * fallback so the fired notification still uses [AdhanPlaybackService] and its
 * Stop Adhan action instead of an actionless Flutter local notification.
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
    const val EXTRA_LOCATION_NAME = "location_name"
    const val EXTRA_LANGUAGE_CODE = "language_code"

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

        // Derive sound name: adhan_fajr for Fajr, else adhan
        val sound = if (prayerKey.lowercase() == "fajr") "adhan_fajr" else "adhan"

        val scheduled = if (am.canScheduleExact()) {
            am.scheduleExact(
                notificationId,
                prayerName,
                prayerKey,
                triggerAtMillis,
                sound,
            )
        } else {
            am.scheduleInexact(
                notificationId,
                prayerName,
                prayerKey,
                triggerAtMillis,
                sound,
            )
        }

        if (scheduled) {
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
        locationName: String = "",
        languageCode: String = "",
    ): Boolean {
        val am = getAlarmManager(context)
        val st = getStorage(context)

        val scheduled = if (am.canScheduleExact()) {
            am.scheduleExact(
                notificationId,
                prayerName,
                prayerKey,
                triggerAtMillis,
                sound,
                locationName,
                languageCode,
            )
        } else {
            am.scheduleInexact(
                notificationId,
                prayerName,
                prayerKey,
                triggerAtMillis,
                sound,
                locationName,
                languageCode,
            )
        }

        if (scheduled) {
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
