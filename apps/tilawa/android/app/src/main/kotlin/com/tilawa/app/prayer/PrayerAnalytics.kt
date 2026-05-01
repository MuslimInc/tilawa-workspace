package com.tilawa.app.prayer

import android.content.Context
import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.crashlytics.FirebaseCrashlytics

/**
 * Interface for tracking prayer-related events and errors.
 * This allows us to mock analytics in unit tests.
 */
interface PrayerAnalytics {
    fun logEvent(name: String, params: Map<String, Any?> = emptyMap())
    fun logError(
        message: String,
        error: Throwable? = null,
        context: Map<String, Any?> = emptyMap()
    )
}

/**
 * Production implementation using Firebase Analytics and Crashlytics.
 */
class FirebasePrayerAnalytics(context: Context) : PrayerAnalytics {
    private val analytics by lazy { FirebaseAnalytics.getInstance(context) }
    private val crashlytics by lazy { FirebaseCrashlytics.getInstance() }

    override fun logEvent(name: String, params: Map<String, Any?>) {
        val bundle = Bundle().apply {
            params.forEach { (key, value) ->
                when (value) {
                    is String -> putString(key, value)
                    is Int -> putInt(key, value)
                    is Long -> putLong(key, value)
                    is Double -> putDouble(key, value)
                    is Boolean -> putBoolean(key, value)
                }
            }
        }
        analytics.logEvent(name, bundle)
    }

    override fun logError(
        message: String,
        error: Throwable?,
        context: Map<String, Any?>
    ) {
        crashlytics.log(message)
        context.forEach { (key, value) ->
            when (value) {
                is String -> crashlytics.setCustomKey(key, value)
                is Int -> crashlytics.setCustomKey(key, value)
                is Long -> crashlytics.setCustomKey(key, value)
                is Float -> crashlytics.setCustomKey(key, value)
                is Double -> crashlytics.setCustomKey(key, value)
                is Boolean -> crashlytics.setCustomKey(key, value)
            }
        }
        error?.let { crashlytics.recordException(it) }
    }
}

/**
 * Event names for Prayer/Adhan monitoring.
 */
object PrayerEvents {
    const val SCHEDULE_STARTED = "prayer_notification_schedule_started"
    const val TRIGGERED = "prayer_notification_triggered"
    const val SCHEDULE_SUCCESS = "native_adhan_schedule_success"
    const val SCHEDULE_FAILED = "native_adhan_schedule_failed"
    const val FALLBACK_USED = "adhan_fallback_used"
    const val PLAYBACK_STARTED = "native_adhan_playback_started"
    const val PLAYBACK_COMPLETED = "native_adhan_playback_completed"
    const val PLAYBACK_FAILED = "native_adhan_playback_failed"
    const val STOP_CLICKED = "adhan_stop_button_clicked"
    const val DUPLICATE_GUARD = "duplicate_audio_guard_triggered"
    const val PERMISSION_CLEANUP = "permission_revoked_cleanup_completed"
    const val WATCHDOG_TRIGGERED = "watchdog_triggered"
    const val WATCHDOG_COMPLETED = "watchdog_completed"
    const val WATCHDOG_FAILED = "watchdog_failed"
    const val WATCHDOG_TIMEOUT = "watchdog_timeout_occurred"
    const val BOOT_TRIGGERED = "boot_receiver_triggered"
}
