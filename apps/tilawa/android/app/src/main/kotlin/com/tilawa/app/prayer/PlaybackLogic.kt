package com.tilawa.app.prayer

import android.content.Intent
import android.media.AudioManager
import android.util.Log

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

                PlaybackAction.PLAY(
                    prayerName = name,
                    prayerKey = key,
                    sound = sound,
                    scheduledMs = scheduledMs,
                    receiverTime = receiverTime
                )
            }
            else -> PlaybackAction.NONE
        }
        return action
    }

    fun getNotificationTitle(prayerName: String): String {
        if (prayerName.isBlank()) return strings.getString("app_name")
        
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
        val receiverTime: Long
    ) : PlaybackAction()
    object NONE : PlaybackAction()
}

interface StringProvider {
    fun getString(key: String): String
}

interface ServiceActions {
    fun stopPlayback()
}
