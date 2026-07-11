package com.tilawa.app.widget.athkar

import java.util.Calendar

internal enum class AthkarPeriod { MORNING, EVENING }

/**
 * Resolved window state: which set applies now, the stable key anchoring
 * per-instance progress, and when the window next flips.
 */
internal data class AthkarPeriodState(
    val period: AthkarPeriod,
    val periodKey: String,
    val nextTransitionMs: Long,
)

/**
 * Pure clock-window rules for the athkar widget (spec 041, US3). Mirrors the
 * Dart `AthkarWidgetPeriodResolver`: morning 04:00–14:59, evening
 * 15:00–03:59; the evening occurrence spanning midnight keeps the key of the
 * day it started (03:00 belongs to yesterday's evening, so progress is NOT
 * reset at midnight).
 */
internal object AthkarWidgetLogic {
    const val MORNING_START_HOUR = 4
    const val EVENING_START_HOUR = 15

    fun resolveState(nowMs: Long): AthkarPeriodState {
        val now = Calendar.getInstance().apply { timeInMillis = nowMs }
        val hour = now.get(Calendar.HOUR_OF_DAY)

        if (hour in MORNING_START_HOUR until EVENING_START_HOUR) {
            val transition = (now.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, EVENING_START_HOUR)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            return AthkarPeriodState(
                period = AthkarPeriod.MORNING,
                periodKey = "M-${dateKey(now)}",
                nextTransitionMs = transition.timeInMillis,
            )
        }

        // Evening: anchor to the day the window started (15:00).
        val anchor = (now.clone() as Calendar).apply {
            if (hour < MORNING_START_HOUR) add(Calendar.DAY_OF_MONTH, -1)
        }
        val transition = (anchor.clone() as Calendar).apply {
            add(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, MORNING_START_HOUR)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return AthkarPeriodState(
            period = AthkarPeriod.EVENING,
            periodKey = "E-${dateKey(anchor)}",
            nextTransitionMs = transition.timeInMillis,
        )
    }

    /**
     * Progress index to display for a stored (key, index) pair: a stale key
     * resets progress to 0 (new window occurrence), and the index is clamped
     * so a shrunken set after a content update can never crash the render.
     */
    fun effectiveIndex(
        storedPeriodKey: String?,
        storedIndex: Int,
        currentPeriodKey: String,
        setSize: Int,
    ): Int {
        if (setSize <= 0) return 0
        if (storedPeriodKey != currentPeriodKey) return 0
        return storedIndex.coerceIn(0, setSize)
    }

    private fun dateKey(calendar: Calendar): String {
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        return "%04d-%02d-%02d".format(year, month, day)
    }
}
