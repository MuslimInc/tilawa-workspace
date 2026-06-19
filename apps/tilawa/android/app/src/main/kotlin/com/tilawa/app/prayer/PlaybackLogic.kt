package com.tilawa.app.prayer

import android.content.Intent
import android.media.AudioManager

internal class PlaybackLogic(
    private val strings: StringProvider,
    private val service: ServiceActions,
    private val analytics: PrayerAnalytics? = null
) : AudioManager.OnAudioFocusChangeListener {
    fun handleIntent(intent: Intent?): PlaybackAction {
        val action = when (intent?.action) {
            "com.tilawa.app.prayer.ACTION_STOP" -> {
                analytics?.logEvent(PrayerEvents.STOP_CLICKED)
                PlaybackAction.STOP
            }
            "com.tilawa.app.prayer.ACTION_PLAY", null -> {
                val name = intent?.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME).orEmpty()
                val key = intent?.getStringExtra(AdhanScheduler.EXTRA_PRAYER_KEY).orEmpty()
                val sound = intent?.getStringExtra(AdhanScheduler.EXTRA_SOUND) ?: "adhan"
                val scheduledMs = intent?.getLongExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, 0L) ?: 0L
                val receiverTime = intent?.getLongExtra("receiver_time", 0L) ?: 0L
                val locationName =
                    intent?.getStringExtra(AdhanScheduler.EXTRA_LOCATION_NAME).orEmpty()
                val languageCode =
                    intent?.getStringExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE).orEmpty()

                PlaybackAction.PLAY(
                    prayerName = name,
                    prayerKey = key,
                    sound = sound,
                    scheduledMs = scheduledMs,
                    receiverTime = receiverTime,
                    locationName = locationName,
                    languageCode = languageCode,
                )
            }
            else -> PlaybackAction.NONE
        }
        return action
    }

    fun getNotificationTitle(prayerName: String, locationName: String = ""): String {
        val prayerLabel = localizedPrayerLabel(prayerName)
        if (prayerLabel.isBlank()) {
            return strings.getString("app_name")
        }
        if (locationName.isBlank()) {
            return prayerLabel
        }
        return strings.formatString(
            "adhan_notification_title",
            prayerLabel,
            locationName,
        )
    }

    fun getNotificationBody(locationName: String = ""): String {
        return if (locationName.isBlank()) {
            strings.getString("adhan_notification_body")
        } else {
            strings.formatString(
                "adhan_notification_body_with_location",
                locationName,
            )
        }
    }

    private fun localizedPrayerLabel(prayerName: String): String {
        if (prayerName.isBlank()) return ""

        return when (prayerName.lowercase()) {
            "fajr" -> strings.getString("prayer_fajr")
            "dhuhr" -> strings.getString("prayer_dhuhr")
            "asr" -> strings.getString("prayer_asr")
            "maghrib" -> strings.getString("prayer_maghrib")
            "isha" -> strings.getString("prayer_isha")
            "sunrise" -> strings.getString("prayer_sunrise")
            else -> prayerName.replaceFirstChar { it.uppercase() }
        }
    }

    override fun onAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                analytics?.logEvent(PrayerEvents.PLAYBACK_FAILED, mapOf("reason" to "audio_focus_loss"))
                service.stopPlayback()
            }
        }
    }
}

sealed class PlaybackAction {
    object STOP : PlaybackAction()
    data class PLAY(
        val prayerName: String,
        val prayerKey: String,
        val sound: String,
        val scheduledMs: Long,
        val receiverTime: Long,
        val locationName: String = "",
        val languageCode: String = "",
    ) : PlaybackAction()
    object NONE : PlaybackAction()
}

interface StringProvider {
    fun getString(key: String): String
    fun formatString(key: String, vararg args: Any): String
}

interface ServiceActions {
    fun stopPlayback()
}
