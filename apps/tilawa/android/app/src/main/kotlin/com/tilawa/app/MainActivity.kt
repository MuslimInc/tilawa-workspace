package com.tilawa.app

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.ryanheise.audioservice.AudioServiceActivity
import com.tilawa.app.auth.GoogleSignInPrepareChannel
import com.tilawa.app.prayer.AdhanScheduler
import com.tilawa.app.prayer.PrayerAdhanMethodChannel
import com.tilawa.app.prayer.PrayerNotificationsWatchdogScheduler
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val WATCHDOG_CHANNEL = "com.tilawa.app/prayer_watchdog"
        private const val LAUNCH_SPLASH_CHANNEL = "com.tilawa.app/launch_splash"
        const val ACTION_OPEN_PRAYER_STATUS =
            "com.tilawa.app.prayer.ACTION_OPEN_PRAYER_STATUS"
        private const val TAG = "MainActivity"
        private const val FIRST_FRAME_TAG = "FirstFrame"

        @Volatile
        var keepLaunchSplashOnScreen: Boolean = true
    }

    private fun firstFrameLog(message: String) {
        Log.d(FIRST_FRAME_TAG, message)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(
            TAG,
            "MAIN_ACTIVITY_ON_CREATE_INTENT action=${intent?.action} extras=${intent?.extras?.keySet()}"
        )
        firstFrameLog("MainActivity.onCreate installSplashScreen")
        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { keepLaunchSplashOnScreen }
        splashScreen.setOnExitAnimationListener { splashScreenView ->
            firstFrameLog("splash exit animation → remove() (no fade)")
            splashScreenView.remove()
        }
        super.onCreate(savedInstanceState)
        firstFrameLog("MainActivity.onCreate complete")
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == ACTION_OPEN_PRAYER_STATUS) {
            val prayerName = intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME) ?: ""
            val prayerKey = intent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_KEY)
                ?: prayerName.lowercase()
            val id = intent.getIntExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, -1)
            val scheduledMs = intent.getLongExtra(
                AdhanScheduler.EXTRA_SCHEDULED_MS,
                System.currentTimeMillis(),
            )
            val payload = JSONObject().apply {
                put("type", "prayer")
                put("prayer", prayerName)
                put("prayer_name", prayerName)
                put("prayer_key", prayerKey)
                put("scheduled_time_ms", scheduledMs)
                put("scheduled_ms", scheduledMs)
                put("notification_id", id)
                put("adhan_enabled", intent.getBooleanExtra("adhan_enabled", true))
                put("is_adhan_playing", intent.getBooleanExtra("is_adhan_playing", true))
                if (intent.hasExtra("actual_trigger_time_ms")) {
                    put(
                        "actual_trigger_time_ms",
                        intent.getLongExtra("actual_trigger_time_ms", 0L),
                    )
                }
            }.toString()
            PrayerAdhanMethodChannel.notifyNotificationTapped(prayerKey, payload)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d(
            TAG,
            "MAIN_ACTIVITY_ON_NEW_INTENT action=${intent.action} extras=${intent.extras?.keySet()}"
        )
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register custom channels after super to ensure they are registered
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATCHDOG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensurePeriodicWatchdogScheduled" -> {
                        PrayerNotificationsWatchdogScheduler.enqueuePeriodic(this@MainActivity)
                        result.success(null)
                    }
                    "runPrayerNotificationWatchdogNow" -> {
                        PrayerNotificationsWatchdogScheduler.enqueueOneTime(this@MainActivity)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        PrayerAdhanMethodChannel.register(
            flutterEngine.dartExecutor.binaryMessenger,
            this,
        )

        GoogleSignInPrepareChannel.register(
            flutterEngine.dartExecutor.binaryMessenger,
            this,
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCH_SPLASH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ready" -> {
                        firstFrameLog("MethodChannel ready → keepLaunchSplashOnScreen=false")
                        keepLaunchSplashOnScreen = false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun getRenderMode(): RenderMode {
        // A cold start from a notification can launch through the lockscreen/
        // notification shade path. With SurfaceView, Flutter delays the first
        // Android draw until the first Flutter frame, which can deadlock that
        // transition and leave a persistent black screen. TextureView avoids
        // the pre-draw gate for this activity.
        return RenderMode.texture
    }
}
