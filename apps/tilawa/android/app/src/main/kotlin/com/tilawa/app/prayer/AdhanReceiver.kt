package com.tilawa.app.prayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.tilawa.app.MainActivity
import com.tilawa.app.R

/**
 * Fires when an Adhan AlarmManager alarm goes off. Hands control to
 * [AdhanPlaybackService] which actually plays the audio under a
 * `mediaPlayback` foreground service so playback survives app termination
 * and is allowed past Android's background-start restrictions.
 */
internal class AdhanReceiver : BroadcastReceiver() {
    companion object {
        // Must match Flutter [PrayerNotificationConfig.adhanChannelId]: the
        // audible channel (adhan sound, USAGE_ALARM, no vibration) created at
        // app startup. Reused for the background-start fallback below.
        private const val AUDIBLE_ADHAN_CHANNEL_ID = "com.tilawa.app.prayer_adhan_v5"
        private const val AUDIBLE_ADHAN_CHANNEL_NAME = "Prayer Times (Adhan)"
    }

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
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(context, serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            // Android 12+ forbids starting a foreground service from the
            // background without an FGS-start exemption. Exact alarms
            // (setAlarmClock) grant one; the inexact fallback used when the user
            // has not granted exact-alarm access does NOT, so a backgrounded
            // alarm here throws ForegroundServiceStartNotAllowedException. Never
            // crash the process — post an audible notification on the adhan
            // channel instead so the user still hears the adhan.
            val fgsBlocked = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                e is android.app.ForegroundServiceStartNotAllowedException
            Log.w(
                "AdhanReceiver",
                "startForegroundService rejected (fgsBlocked=$fgsBlocked); posting audible fallback",
                e,
            )
            analytics.logError(
                "Adhan foreground service start rejected",
                e,
                mapOf(
                    "prayer_name" to prayerName,
                    "prayer_key" to prayerKey,
                    "exact_alarm_permission_granted" to AdhanScheduler.canScheduleExact(context),
                    "android_sdk" to Build.VERSION.SDK_INT,
                    "device_manufacturer" to Build.MANUFACTURER,
                    "fgs_not_allowed" to fgsBlocked,
                ),
            )
            analytics.logEvent(
                PrayerEvents.FALLBACK_USED,
                mapOf(
                    "reason" to "fgs_start_not_allowed",
                    "prayer_key" to prayerKey,
                ),
            )
            postAudibleFallbackNotification(
                context = context,
                analytics = analytics,
                notificationId = notificationId,
                prayerName = prayerName,
                prayerKey = prayerKey,
                scheduledMs = scheduledMs,
                locationName = locationName,
                languageCode = languageCode,
            )
        }
    }

    /**
     * Fallback used when the OS rejects the foreground-service start (typically
     * a backgrounded inexact alarm on Android 12+). Posts a one-shot audible
     * notification on the adhan channel so the adhan sound still plays without a
     * foreground service. No Stop action or per-prayer sound — the channel owns
     * a single fixed adhan sound — which is the acceptable degradation for a
     * path that would otherwise crash.
     */
    private fun postAudibleFallbackNotification(
        context: Context,
        analytics: PrayerAnalytics,
        notificationId: Int,
        prayerName: String,
        prayerKey: String,
        scheduledMs: Long,
        locationName: String,
        languageCode: String,
    ) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureAudibleAdhanChannel(context, nm)

        val localizedResources =
            NotificationLocaleHelper.localizedResources(context, languageCode)
        val strings = object : StringProvider {
            override fun getString(key: String): String {
                val resId = localizedResources.getIdentifier(key, "string", context.packageName)
                return if (resId != 0) localizedResources.getString(resId) else key
            }

            override fun formatString(key: String, vararg args: Any): String {
                val resId = localizedResources.getIdentifier(key, "string", context.packageName)
                return if (resId != 0) localizedResources.getString(resId, *args) else key
            }
        }
        val logic = PlaybackLogic(
            strings,
            object : ServiceActions {
                override fun stopPlayback() = Unit
            },
            analytics,
        )
        val resolvedLocationName = locationName.ifBlank {
            DefaultPrayerStorage(context).getLastNotificationLocationName().orEmpty()
        }
        val title = logic.getNotificationTitle(prayerName, resolvedLocationName)
        val body = logic.getNotificationBody(resolvedLocationName)

        val openIntent = PendingIntent.getActivity(
            context,
            notificationId,
            Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                action = MainActivity.ACTION_OPEN_PRAYER_STATUS
                putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, prayerName)
                putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, prayerKey)
                putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, notificationId)
                putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, scheduledMs)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, AUDIBLE_ADHAN_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
                .setSound(Uri.parse("android.resource://${context.packageName}/${R.raw.adhan}"))
                .setPriority(Notification.PRIORITY_HIGH)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.notification_accent))
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(openIntent)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
        nm.notify(notificationId, notification)
    }

    /**
     * Creates the audible adhan channel only if Flutter has not already created
     * it. Recreating an existing channel would resurrect its stored settings, so
     * we leave any existing channel untouched.
     */
    private fun ensureAudibleAdhanChannel(context: Context, nm: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (nm.getNotificationChannel(AUDIBLE_ADHAN_CHANNEL_ID) != null) return
        val soundUri = Uri.parse("android.resource://${context.packageName}/${R.raw.adhan}")
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        nm.createNotificationChannel(
            NotificationChannel(
                AUDIBLE_ADHAN_CHANNEL_ID,
                AUDIBLE_ADHAN_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                setSound(soundUri, attrs)
                enableVibration(false)
            },
        )
    }
}
