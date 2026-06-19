package com.tilawa.app.prayer

import android.content.Context

/**
 * Interface for persisting adhan-related state.
 */
interface PrayerStorage {
    fun getActiveIds(): Set<Int>
    fun addActiveId(id: Int)
    fun removeActiveId(id: Int)
    fun clearActiveIds()
    
    fun getPendingAlarmsJson(): String?
    fun setPendingAlarmsJson(json: String?)
    
    fun setNeedsReschedule(needs: Boolean)
    fun needsReschedule(): Boolean

    fun setLastNotificationLocationName(name: String?)
    fun getLastNotificationLocationName(): String?
}

/**
 * Interface for scheduling alarms.
 */
interface PrayerAlarmManager {
    fun scheduleExact(
        id: Int,
        name: String,
        key: String,
        triggerMs: Long,
        sound: String,
        locationName: String = "",
        languageCode: String = "",
    ): Boolean
    fun cancel(id: Int)
    fun cancelAll(ids: Set<Int>)
    fun canScheduleExact(): Boolean
}

data class AlarmMetadata(
    val id: Int,
    val name: String,
    val key: String,
    val triggerMs: Long,
    val sound: String,
    val locationName: String = "",
    val languageCode: String = "",
)
