package com.tilawa.app.prayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioManager
import android.media.AudioFocusRequest
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.PlaybackException
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.content.ContextCompat
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
        // Must match Flutter [PrayerNotificationConfig.silentAdhanChannelId].
        // Native MediaPlayer owns audio; the FGS notification must stay silent
        // and vibration-free (the vibration motor is audible over the start of
        // playback), so we never reuse the audible adhan channel. Config
        // changes require a new `_vN` suffix: Android resurrects deleted
        // channels with their old settings when the same ID is recreated.
        private const val CHANNEL_ID = "com.tilawa.app.prayer_adhan_silent_v5"
        private const val CHANNEL_NAME = "Prayer Times (Silent)"
        private const val WAKE_LOCK_TAG = "Tilawa::AdhanPlayback"
        private const val WAKE_LOCK_TIMEOUT_MS = 5L * 60L * 1000L

        var isRunning = false
            private set

        /// Snapshot of the currently-playing adhan, exposed so the app can
        /// route the user back to the status screen on resume / cold start
        /// after the foreground notification has been swiped away.
        @Volatile
        var activePayload: ActiveAdhanPayload? = null
            private set

        @androidx.annotation.VisibleForTesting
        fun setActivePayloadForTest(payload: ActiveAdhanPayload?) {
            activePayload = payload
        }

        /// Process-wide so duplicate alarm deliveries are still rejected after
        /// the service instance that played the event has been destroyed.
        private var startGate = AdhanStartGate()

        @androidx.annotation.VisibleForTesting
        fun resetStartGateForTest() {
            startGate = AdhanStartGate()
        }
    }

    data class ActiveAdhanPayload(
        val prayerName: String,
        val prayerKey: String,
        val sound: String,
        val scheduledMs: Long,
        val notificationId: Int,
        val locationName: String = "",
        val languageCode: String = "",
    )

    private var exoPlayer: ExoPlayer? = null
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

                override fun formatString(key: String, vararg args: Any): String {
                    val resId = resources.getIdentifier(key, "string", packageName)
                    return if (resId != 0) getString(resId, *args) else key
                }
            },
            object : ServiceActions {
                override fun stopPlayback() {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        stopForeground(STOP_FOREGROUND_REMOVE)
                    } else {
                        @Suppress("DEPRECATION")
                        stopForeground(true)
                    }
                    stopSelf()
                }
            },
            analytics
        )
    }

    private var isPlayingInternally = false
    private var completedSuccessfully = false
    private var startTimeMs: Long = 0
    private var playbackSessionId: String? = null

    private fun logDebug(message: String) {
        val isDebuggable =
            (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebuggable) Log.d(TAG, message)
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        
        if (intent?.action == ACTION_PLAY && isPlayingInternally) {
            Log.w(TAG, "Duplicate ACTION_PLAY ignored")
            analytics.logEvent(PrayerEvents.DUPLICATE_GUARD)
            return START_NOT_STICKY
        }
        
        when (val action = logic.handleIntent(intent)) {
            is PlaybackAction.STOP -> {
                logDebug("ACTION_STOP received")
                removeForegroundNotification()
                stopSelf()
            }
            is PlaybackAction.PLAY -> {
                logDebug("ACTION_PLAY received")
                logDebug(
                    "ADHAN_AUDIT source=playback_service event=service_start prayerKey=${action.prayerKey} " +
                        "prayerName=${action.prayerName} scheduledMs=${action.scheduledMs} " +
                        "notificationId=$FOREGROUND_NOTIFICATION_ID channelId=$CHANNEL_ID"
                )
                
                // Observability: Trigger Latency and Service Start Latency
                if (action.scheduledMs > 0 && action.receiverTime > 0) {
                    analytics.logEvent("prayer_trigger_delta", mapOf(
                        "delta_ms" to (action.receiverTime - action.scheduledMs),
                        "prayer_key" to action.prayerKey,
                        "prayer_name" to action.prayerName
                    ))
                }
                
                val startMs = System.currentTimeMillis()
                val latencyMs = if (action.receiverTime > 0) startMs - action.receiverTime else null
                
                analytics.logEvent(PrayerEvents.SERVICE_STARTED, mapOf(
                    "prayer_name" to action.prayerName,
                    "prayer_key" to action.prayerKey,
                    "service_start_latency_ms" to latencyMs,
                    "android_sdk" to Build.VERSION.SDK_INT,
                    "device_brand" to Build.BRAND
                ))

                AdhanQALogger.logEvent(
                    context = this,
                    eventName = "SERVICE_STARTED",
                    prayerName = action.prayerName,
                    scheduledMs = action.scheduledMs,
                    triggerMs = action.receiverTime,
                    latencyMs = latencyMs,
                    sound = action.sound
                )

                startPlayback(
                    action.prayerName,
                    action.prayerKey,
                    action.sound,
                    action.scheduledMs,
                    action.locationName,
                    action.languageCode,
                )
            }
            PlaybackAction.NONE -> Unit
        }
        return START_NOT_STICKY
    }

    private fun startPlayback(
        prayerName: String,
        prayerKey: String,
        sound: String,
        scheduledMs: Long,
        locationName: String = "",
        languageCode: String = "",
    ) {
        activePayload = ActiveAdhanPayload(
            prayerName = prayerName,
            prayerKey = prayerKey,
            sound = sound,
            scheduledMs = scheduledMs,
            notificationId = FOREGROUND_NOTIFICATION_ID,
            locationName = locationName,
            languageCode = languageCode,
        )
        val notification = buildNotification(
            prayerName,
            prayerKey,
            FOREGROUND_NOTIFICATION_ID,
            scheduledMs,
            locationName,
            languageCode,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                FOREGROUND_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(FOREGROUND_NOTIFICATION_ID, notification)
        }

        // Idempotency gate: exactly one playback session per adhan event, even
        // when the first session already ended (which the isPlayingInternally
        // guard cannot cover). Checked after startForeground to honour the
        // startForegroundService contract on rejected duplicates.
        val sessionId = startGate.tryStart(
            prayerKey = prayerKey,
            scheduledMs = scheduledMs,
            nowMs = System.currentTimeMillis(),
        )
        if (sessionId == null) {
            Log.w(
                TAG,
                "Duplicate adhan event ignored: prayerKey=$prayerKey scheduledMs=$scheduledMs",
            )
            analytics.logEvent(
                PrayerEvents.DUPLICATE_GUARD,
                mapOf(
                    "reason" to "duplicate_event",
                    "prayer_key" to prayerKey,
                    "scheduled_ms" to scheduledMs,
                ),
            )
            AdhanQALogger.logEvent(
                context = this,
                eventName = "DUPLICATE_START_IGNORED",
                prayerName = prayerName,
                scheduledMs = scheduledMs,
            )
            activePayload = null
            removeForegroundNotification()
            stopSelf()
            return
        }
        playbackSessionId = sessionId
        logDebug(
            "ADHAN_AUDIT source=playback_service event=playback_session_started sessionId=$sessionId " +
                "prayerKey=$prayerKey scheduledMs=$scheduledMs",
        )
        acquireWakeLock()
        
        analytics.logEvent("adhan_playback_started", mapOf(
            "prayer_name" to prayerName,
            "prayer_key" to prayerKey,
            "sound_name" to sound,
            "session_id" to sessionId
        ))
        
        logDebug("startPlayback: initializing ExoPlayer for sound: $sound")
        try {
            val adhanResId = resolveAdhanRawResource(sound)

            exoPlayer = androidx.media3.exoplayer.ExoPlayer.Builder(this@AdhanPlaybackService).build().apply {
                val mediaItem = androidx.media3.common.MediaItem.fromUri(Uri.parse("android.resource://$packageName/$adhanResId"))
                setMediaItem(mediaItem)
                
                // Use USAGE_ALARM for better background focus priority on Android 14+
                val audioAttributes = androidx.media3.common.AudioAttributes.Builder()
                    .setUsage(androidx.media3.common.C.USAGE_ALARM)
                    .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build()
                
                // false = disable automatic audio focus handling, as it is unsupported for USAGE_ALARM
                setAudioAttributes(audioAttributes, false)
                
                addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        if (playbackState == Player.STATE_ENDED) {
                            logDebug("Playback completed")
                            logDebug(
                                "ADHAN_AUDIT source=playback_service event=playback_completed prayerKey=$prayerKey " +
                                    "prayerName=$prayerName scheduledMs=$scheduledMs notificationId=$FOREGROUND_NOTIFICATION_ID " +
                                    "channelId=$CHANNEL_ID sessionId=$sessionId"
                            )
                            val durationMs = if (startTimeMs > 0) System.currentTimeMillis() - startTimeMs else null
                            analytics.logEvent("adhan_playback_completed", mapOf(
                                "prayer_name" to prayerName,
                                "playback_duration_ms" to durationMs,
                                "completed" to true,
                                "session_id" to sessionId
                            ))
                            AdhanQALogger.logEvent(
                                context = this@AdhanPlaybackService,
                                eventName = "PLAYBACK_COMPLETED",
                                details = "session=$sessionId"
                            )
                            completedSuccessfully = true
                            isPlayingInternally = false
                            removeForegroundNotification()
                            stopSelf()
                        }
                    }

                    override fun onPlayerError(error: PlaybackException) {
                        Log.e(TAG, "ExoPlayer error: ${error.message}", error)
                        analytics.logEvent("adhan_playback_abnormal_termination", mapOf(
                            "reason" to "exoplayer_error_${error.errorCode}",
                            "error_message" to error.message.toString(),
                            "abnormal_termination" to true
                        ))
                        isPlayingInternally = false
                        stopSelf()
                    }
                })

                prepare()
                
                // Request focus as an ALARM manually
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val focusRequest = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                        .setAudioAttributes(
                            android.media.AudioAttributes.Builder()
                                .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_MUSIC)
                                .build()
                        )
                        .build()
                } else {
                    null
                }

                val focusResult = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && focusRequest != null) {
                    this@AdhanPlaybackService.audioFocusRequest = focusRequest
                    audioManager.requestAudioFocus(focusRequest)
                } else {
                    @Suppress("DEPRECATION")
                    audioManager.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                }

                if (focusResult != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                    Log.w(TAG, "Audio focus denied ($focusResult), but proceeding with ALARM usage")
                }
                
                isPlayingInternally = true
                AdhanQALogger.logEvent(
                    context = this@AdhanPlaybackService,
                    eventName = "PLAYBACK_STARTED",
                    sound = sound,
                    details = "session=$sessionId"
                )
                playWhenReady = true
            }

            startTimeMs = System.currentTimeMillis()
            logDebug("ExoPlayer started successfully")

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

    private fun resolveAdhanRawResource(sound: String): Int {
        val requestedResId = resources.getIdentifier(sound, "raw", packageName)
        if (requestedResId != 0) {
            return requestedResId
        }
        if (sound != "adhan") {
            Log.w(TAG, "Sound resource '$sound' not found, falling back to 'adhan'")
        }
        return R.raw.adhan
    }

    private fun stopPlayback() {
        try {
            exoPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
        } catch (_: Throwable) {
        }
        exoPlayer = null
        abandonAudioFocus()
        releaseWakeLock()
    }

    private fun removeForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(FOREGROUND_NOTIFICATION_ID)
    }

    override fun onDestroy() {
        logDebug(
            "ADHAN_AUDIT source=playback_service event=service_destroyed notificationId=$FOREGROUND_NOTIFICATION_ID " +
                "channelId=$CHANNEL_ID sessionId=$playbackSessionId"
        )
        if (!completedSuccessfully && isPlayingInternally) {
            Log.w(TAG, "Abnormal termination: service destroyed before completion")
            analytics.logEvent(PrayerEvents.ABNORMAL_TERMINATION, mapOf(
                "reason" to "onDestroy_without_completion",
                "device_brand" to Build.BRAND,
                "android_sdk" to Build.VERSION.SDK_INT,
                "abnormal_termination" to true
            ))
            AdhanQALogger.logEvent(
                context = this,
                eventName = "ABNORMAL_TERMINATION",
                details = "onDestroy without completion"
            )
        }
        AdhanQALogger.logEvent(
            context = this,
            eventName = "SERVICE_DESTROYED"
        )
        stopPlayback()
        isRunning = false
        activePayload = null
        super.onDestroy()
    }

    private fun buildNotification(
        prayerName: String,
        prayerKey: String,
        notificationId: Int,
        scheduledMs: Long,
        locationName: String = "",
        languageCode: String = "",
    ): Notification {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        ensureSilentPlaybackChannel(nm)
        val localizedLogic = localizedPlaybackLogic(languageCode)
        val localizedResources =
            NotificationLocaleHelper.localizedResources(this, languageCode)
        val resolvedLocationName = locationName.ifBlank {
            DefaultPrayerStorage(this).getLastNotificationLocationName().orEmpty()
        }
        val openIntent = PendingIntent.getActivity(
            this,
            notificationId,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                action = MainActivity.ACTION_OPEN_PRAYER_STATUS
                putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, prayerName)
                putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, prayerKey)
                putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, notificationId)
                putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, scheduledMs)
                putExtra("actual_trigger_time_ms", System.currentTimeMillis())
                putExtra("adhan_enabled", true)
                putExtra("is_adhan_playing", true)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        logDebug(
            "NATIVE_NOTIFICATION_TAP_INTENT_CREATED prayerKey=$prayerKey notificationId=$notificationId target=${MainActivity::class.java.simpleName}",
        )
        val stopIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, AdhanPlaybackService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val title = localizedLogic.getNotificationTitle(prayerName, resolvedLocationName)

        val contentText = localizedLogic.getNotificationBody(resolvedLocationName)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(this, R.color.notification_accent))
            .setContentTitle(title)
            .setContentText(contentText)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(
                Notification.Action.Builder(
                    null,
                    localizedResources.getString(R.string.stop_adhan),
                    stopIntent,
                ).build(),
            )
            .build()
    }

    private fun localizedPlaybackLogic(languageCode: String): PlaybackLogic {
        val localizedResources =
            NotificationLocaleHelper.localizedResources(this, languageCode)
        return PlaybackLogic(
            object : StringProvider {
                override fun getString(key: String): String {
                    val resId = localizedResources.getIdentifier(key, "string", packageName)
                    return if (resId != 0) localizedResources.getString(resId) else key
                }

                override fun formatString(key: String, vararg args: Any): String {
                    val resId = localizedResources.getIdentifier(key, "string", packageName)
                    return if (resId != 0) localizedResources.getString(resId, *args) else key
                }
            },
            // ServiceActions is unused in the localization-only path; lifecycle is
            // owned by the main `logic` lazy instance which holds the real callback.
            object : ServiceActions {
                override fun stopPlayback() = Unit
            },
            analytics,
        )
    }

    private fun ensureSilentPlaybackChannel(nm: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        // Best-effort guard against a misconfigured channel: audible (only
        // MediaPlayer may play adhan) or vibrating (the vibration motor is
        // audible over the start of playback). Note Android may resurrect the
        // old settings on recreate — real config changes ship under a new
        // CHANNEL_ID, this only heals in-process anomalies.
        val existing = nm.getNotificationChannel(CHANNEL_ID)
        if (existing != null && (existing.sound != null || existing.shouldVibrate())) {
            nm.deleteNotificationChannel(CHANNEL_ID)
        }
        if (nm.getNotificationChannel(CHANNEL_ID) == null) {
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
