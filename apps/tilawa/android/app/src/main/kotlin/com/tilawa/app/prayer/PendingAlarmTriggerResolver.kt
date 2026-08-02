package com.tilawa.app.prayer

import java.util.Calendar
import java.util.TimeZone

/**
 * Rebuilds AlarmManager trigger epochs from persisted local wall-clock fields
 * so DST / timezone / system-time changes do not reuse a stale absolute millis.
 *
 * Legacy JSON without wall-clock fields keeps the stored [AlarmMetadata.triggerMs].
 */
internal object PendingAlarmTriggerResolver {
    fun resolveTriggerMs(
        entry: AlarmMetadata,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): Long {
        if (!entry.hasLocalWallClock) {
            return entry.triggerMs
        }
        val calendar = Calendar.getInstance(timeZone)
        calendar.set(Calendar.MILLISECOND, 0)
        calendar.set(
            entry.year!!,
            entry.month!! - 1,
            entry.day!!,
            entry.hour!!,
            entry.minute!!,
            0,
        )
        return calendar.timeInMillis
    }
}
