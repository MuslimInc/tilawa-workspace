package com.tilawa.app.prayer.widget

/**
 * Resolved display state for one render of the prayer widget.
 *
 * [nextPrayerKey]/[nextPrayerTimeMs] are null when every prayer in the
 * snapshot is in the past — the widget then renders the stale state
 * (last-known times + "open app" cue) instead of a countdown, satisfying the
 * "never a blank frame" requirement (spec 041, FR-014).
 */
internal data class PrayerWidgetState(
    val day: PrayerWidgetDay,
    val nextPrayerKey: String?,
    val nextPrayerTimeMs: Long?,
    val locationName: String,
) {
    val isStale: Boolean get() = nextPrayerKey == null
}

/**
 * Pure widget state resolution — no Android dependencies so the
 * next-prayer/rollover/staleness rules are unit-testable in isolation.
 */
internal object PrayerWidgetLogic {

    /**
     * Picks the next upcoming prayer across all snapshot days and the day row
     * to display (the day containing that prayer). Selecting by "first prayer
     * after now" rather than by matching date strings makes the logic immune
     * to timezone and date-key drift between Dart and native.
     *
     * Returns null when the snapshot has no days.
     */
    fun resolveState(snapshot: PrayerWidgetSnapshot, nowMs: Long): PrayerWidgetState? {
        val days = snapshot.days
        if (days.isEmpty()) return null
        for (day in days) {
            for ((key, timeMs) in day.prayers) {
                if (timeMs > nowMs) {
                    return PrayerWidgetState(
                        day = day,
                        nextPrayerKey = key,
                        nextPrayerTimeMs = timeMs,
                        locationName = snapshot.locationName,
                    )
                }
            }
        }
        // Everything is in the past — show the last known day, stale.
        return PrayerWidgetState(
            day = days.last(),
            nextPrayerKey = null,
            nextPrayerTimeMs = null,
            locationName = snapshot.locationName,
        )
    }

    /**
     * When the widget should next re-render: at the upcoming prayer boundary
     * (plus a small grace so the boundary has definitely passed), or null when
     * stale (the 30-minute `updatePeriodMillis` backstop still applies).
     */
    fun nextRefreshAtMs(state: PrayerWidgetState): Long? {
        val next = state.nextPrayerTimeMs ?: return null
        return next + BOUNDARY_GRACE_MS
    }

    private const val BOUNDARY_GRACE_MS = 2_000L
}
