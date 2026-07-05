package com.tilawa.app.prayer

/**
 * Idempotency gate guaranteeing one playback session per adhan event.
 *
 * An event is identified by `prayerKey:scheduledMs`. AlarmManager re-delivery,
 * boot re-arm of an already-fired alarm, or a stray duplicate `ACTION_PLAY`
 * carry the same identity and are rejected inside [windowMs] — even when the
 * first session already ended (completed or stopped by the user), which the
 * `isPlayingInternally` guard in [AdhanPlaybackService] cannot cover.
 *
 * Held in the service's companion so it survives service restarts within the
 * process; process death resets it, which is safe because duplicates arrive
 * within seconds of the original.
 */
internal class AdhanStartGate(
    private val windowMs: Long = DEFAULT_WINDOW_MS,
) {
    companion object {
        /** Longer than one full adhan so a late duplicate is still caught. */
        const val DEFAULT_WINDOW_MS = 5L * 60L * 1000L
    }

    private var lastEventKey: String? = null
    private var lastAcceptedAtMs: Long = 0L
    private var sessionCounter: Long = 0L

    /**
     * Returns a unique playback session id when the event may start, or null
     * when it is a duplicate of the last accepted event within [windowMs].
     * Events without identity (blank key and no scheduled time, e.g. legacy
     * intents) are always accepted.
     */
    @Synchronized
    fun tryStart(prayerKey: String, scheduledMs: Long, nowMs: Long): String? {
        val hasIdentity = prayerKey.isNotBlank() || scheduledMs > 0L
        val eventKey = "$prayerKey:$scheduledMs"
        if (hasIdentity &&
            eventKey == lastEventKey &&
            nowMs - lastAcceptedAtMs < windowMs
        ) {
            return null
        }
        lastEventKey = if (hasIdentity) eventKey else null
        lastAcceptedAtMs = nowMs
        sessionCounter += 1
        return "${prayerKey.ifBlank { "adhan" }}-$scheduledMs-#$sessionCounter"
    }
}
