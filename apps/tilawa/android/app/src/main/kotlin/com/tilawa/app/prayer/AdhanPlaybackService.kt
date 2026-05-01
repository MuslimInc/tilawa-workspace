package com.tilawa.app.prayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import com.tilawa.app.MainActivity
import com.tilawa.app.R

/**
 * Foreground service that plays the adhan when an alarm fires. Uses
 * [MediaPlayer] against the bundled `R.raw.adhan` resource. Lifecycle:
 *
 *   1. [AdhanReceiver] starts this service with [ACTION_PLAY].
 *   2. We promote to foreground (mediaPlayback) so the OS lets us run from
 *      a Doze-bypassing alarm.
 *   3. MediaPlayer plays the bundled adhan; we hold a partial wake lock for
 *      the duration so the device stays awake on the lock screen.
 *   4. On completion (or [ACTION_STOP] from the notification action), we
 *      tear down and `stopSelf()`.
 */
internal class AdhanPlaybackService : Service() {
    companion object {
        const val ACTION_PLAY = "com.tilawa.app.prayer.ACTION_PLAY"
        const val ACTION_STOP = "com.tilawa.app.prayer.ACTION_STOP"

        private const val TAG = "AdhanPlaybackService"
        private const val FOREGROUND_NOTIFICATION_ID = 0x4144_4841 // 'ADHA'
        private const val CHANNEL_ID = "com.tilawa.app.prayer_adhan"
        private const val CHANNEL_NAME = "Prayer Times (Adhan)"
        private const val WAKE_LOCK_TAG = "Tilawa::AdhanPlayback"
        private const val WAKE_LOCK_TIMEOUT_MS = 5L * 60L * 1000L
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    override fun onBind(intent: Intent?): IBinder? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private val analytics by lazy { FirebasePrayerAnalytics(this) }

    private val logic by lazy {
        PlaybackLogic(
            object : StringProvider {
                override fun getString(key: String): String {
                    val resId = resources.getIdentifier(key, "string", packageName)
                    return if (resId != 0) getString(resId) else key
                }
            },
            object : ServiceActions {
                override fun stopPlayback() {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
            },
            analytics
        )
    }

    private var isPlayingInternally = false
    private var completedSuccessfully = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val startTime = System.currentTimeMillis()
        
        if (intent?.action == ACTION_PLAY && isPlayingInternally) {
            Log.w(TAG, "Duplicate ACTION_PLAY ignored")
            analytics.logEvent(PrayerEvents.DUPLICATE_GUARD)
            return START_NOT_STICKY
        }
        
        when (val action = logic.handleIntent(intent)) {
            is PlaybackAction.STOP -> {
                Log.d("AdhanPlaybackService", "ACTION_STOP received")
                @Suppress("DEPRECATION")
                stopForeground(true)
                stopSelf()
            }
            is PlaybackAction.PLAY -> {
                Log.d("AdhanPlaybackService", "ACTION_PLAY received")
                
                // Observability: Trigger Latency and Service Start Latency
                if (action.scheduledMs > 0 && action.receiverTime > 0) {
                    analytics.logEvent("prayer_trigger_delta", mapOf(
                        "delta_ms" to (action.receiverTime - action.scheduledMs),
                        "prayer_name" to action.prayerName
                    ))
                }
                if (action.receiverTime > 0) {
                    analytics.logEvent("prayer_service_start_latency", mapOf(
                        "latency_ms" to (startTime - action.receiverTime),
                        "prayer_name" to action.prayerName
                    ))
                }

                startPlayback(action.prayerName, action.sound)
            }
            PlaybackAction.NONE -> Unit
        }
        return START_NOT_STICKY
    }

    private fun startPlayback(prayerName: String, sound: String) {
        val notification = buildNotification(prayerName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                FOREGROUND_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(FOREGROUND_NOTIFICATION_ID, notification)
        }

        acquireWakeLock()
        
        Log.d(TAG, "startPlayback: initializing MediaPlayer for sound: $sound")
        try {
            var adhanResId = resources.getIdentifier(sound, "raw", packageName)
            if (adhanResId == 0) {
                Log.w(TAG, "Sound resource '$sound' not found, falling back to 'adhan'")
                adhanResId = resources.getIdentifier("adhan", "raw", packageName)
            }
            
            if (adhanResId == 0) {
                Log.e(TAG, "Adhan resource not found")
                stopSelf()
                return
            }

            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AdhanPlaybackService, Uri.parse("android.resource://$packageName/$adhanResId"))
                
                // Use USAGE_ALARM for better background focus priority on Android 14+
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                
                setOnCompletionListener {
                    Log.i(TAG, "Playback completed")
                    analytics.logEvent(PrayerEvents.PLAYBACK_COMPLETED)
                    completedSuccessfully = true
                    isPlayingInternally = false
                    // Keep the notification but stop the foreground service status
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        stopForeground(STOP_FOREGROUND_DETACH)
                    } else {
                        @Suppress("DEPRECATION")
                        stopForeground(false)
                    }
                    stopSelf()
                }
                
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra")
                    analytics.logEvent(PrayerEvents.PLAYBACK_FAILED, mapOf(
                        "error_what" to what,
                        "error_extra" to extra
                    ))
                    isPlayingInternally = false
                    stopSelf()
                    true
                }

                prepare()
                isPlayingInternally = true
            }

            // Request focus as an ALARM
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val audioFocusRequest = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .build()
            } else {
                null
            }

            val focusResult = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && audioFocusRequest != null) {
                this.audioFocusRequest = audioFocusRequest
                audioManager.requestAudioFocus(audioFocusRequest)
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            }

            if (focusResult != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                Log.w(TAG, "Audio focus denied ($focusResult), but proceeding with ALARM usage")
            }

            mediaPlayer?.start()
            Log.i(TAG, "MediaPlayer started successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start playback", e)
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            analytics.logError(
                "Failed to start playback", 
                e,
                mapOf(
                    "prayer_name" to prayerName,
                    "sound" to sound,
                    "exact_alarm_permission_granted" to AdhanScheduler.canScheduleExact(this),
                    "notification_permission_granted" to nm.areNotificationsEnabled(),
                    "device_manufacturer" to Build.MANUFACTURER,
                    "fallback_used" to false
                )
            )
            analytics.logEvent(PrayerEvents.PLAYBACK_FAILED, mapOf("reason" to "initialization_error"))
            stopSelf()
        }
    }

    private fun stopPlayback() {
        try {
            mediaPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
        } catch (_: Throwable) {
        }
        mediaPlayer = null
        abandonAudioFocus()
        releaseWakeLock()
    }

    override fun onDestroy() {
        if (!completedSuccessfully && isPlayingInternally) {
            Log.w(TAG, "Abnormal termination: service destroyed before completion")
            analytics.logEvent("prayer_service_abnormal_termination", mapOf(
                "reason" to "onDestroy_without_completion",
                "device_manufacturer" to Build.MANUFACTURER
            ))
        }
        stopPlayback()
        super.onDestroy()
    }

    private fun buildNotification(prayerName: String): Notification {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            nm.getNotificationChannel(CHANNEL_ID) == null
        ) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    setSound(null, null)
                    enableVibration(false)
                },
            )
        }
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stopIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, AdhanPlaybackService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val title = logic.getNotificationTitle(prayerName)

        val contentText = getString(R.string.adhan_is_playing)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(title)
            .setContentText(contentText)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(
                Notification.Action.Builder(
                    null,
                    getString(R.string.stop_adhan),
                    stopIntent,
                ).build(),
            )
            .build()
    }

    private fun acquireWakeLock() {
        if (wakeLock != null) return
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG)
        wl.setReferenceCounted(false)
        wl.acquire(WAKE_LOCK_TIMEOUT_MS)
        wakeLock = wl
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.takeIf { it.isHeld }?.release()
        } catch (_: Throwable) {
        }
        wakeLock = null
    }


    private fun abandonAudioFocus() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(null)
        }
    }
}
