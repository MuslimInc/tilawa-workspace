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
}

/**
 * Interface for scheduling alarms.
 */
interface PrayerAlarmManager {
    fun scheduleExact(id: Int, name: String, triggerMs: Long): Boolean
    fun cancel(id: Int)
    fun cancelAll(ids: Set<Int>)
    fun canScheduleExact(): Boolean
}
