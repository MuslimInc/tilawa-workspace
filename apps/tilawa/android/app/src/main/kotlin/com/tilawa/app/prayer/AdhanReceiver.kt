package com.tilawa.app.prayer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Fires when an Adhan AlarmManager alarm goes off. Hands control to
 * [AdhanPlaybackService] which actually plays the audio under a
 * `mediaPlayback` foreground service so playback survives app termination
 * and is allowed past Android's background-start restrictions.
 */
internal class AdhanReceiver : BroadcastReceiver() {
    private fun logDebug(context: Context, message: String) {
        if ((context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            Log.d("AdhanReceiver", message)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "com.tilawa.app.prayer.ACTION_FIRE_ADHAN") {
            Log.w("AdhanReceiver", "Received intent with unknown action: ${intent.action}")
            return
        }
        val notificationId = intent.getIntExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, -1)
        val prayerName = intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME).orEmpty()
        val prayerKey = intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_KEY).orEmpty()
        val scheduledMs = intent.getLongExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, 0L)
        val locationName = intent.getStringExtra(AdhanScheduler.EXTRA_LOCATION_NAME).orEmpty()
        val languageCode = intent.getStringExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE).orEmpty()
        val triggerMs = System.currentTimeMillis()
        val deltaMs = if (scheduledMs > 0) triggerMs - scheduledMs else 0L
        
        val analytics = FirebasePrayerAnalytics(context)
        analytics.logEvent(PrayerEvents.RECEIVER_TRIGGERED, mapOf(
            "prayer_name" to prayerName,
            "prayer_key" to prayerKey,
            "alarm_id" to notificationId,
            "scheduled_time_ms" to scheduledMs,
            "actual_trigger_time_ms" to triggerMs,
            "trigger_delta_ms" to deltaMs,
            "android_sdk" to Build.VERSION.SDK_INT,
            "device_brand" to Build.BRAND
        ))

        AdhanQALogger.logEvent(
            context = context,
            eventName = "RECEIVER_TRIGGERED",
            alarmId = notificationId,
            prayerName = prayerName,
            scheduledMs = scheduledMs,
            triggerMs = triggerMs,
            deltaMs = if (scheduledMs > 0) deltaMs else null
        )

        logDebug(context, "Alarm fired: id=$notificationId, name=$prayerName, key=$prayerKey")
        logDebug(
            context,
            "ADHAN_AUDIT source=alarm_receiver event=alarm_fired prayerKey=$prayerKey prayerName=$prayerName " +
                "scheduledMs=$scheduledMs notificationId=$notificationId requestCode=$notificationId triggerMs=$triggerMs"
        )
        if (notificationId < 0) {
            return
        }
        val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, prayerKey)
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, scheduledMs)
            putExtra(AdhanScheduler.EXTRA_SOUND, intent.getStringExtra(AdhanScheduler.EXTRA_SOUND) ?: "adhan")
            if (locationName.isNotBlank()) {
                putExtra(AdhanScheduler.EXTRA_LOCATION_NAME, locationName)
            }
            if (languageCode.isNotBlank()) {
                putExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE, languageCode)
            }
            putExtra("receiver_time", triggerMs)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(context, serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
