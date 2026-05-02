package com.tilawa.app

import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.ryanheise.audioservice.AudioServiceActivity
import com.tilawa.app.prayer.PrayerAdhanMethodChannel
import com.tilawa.app.prayer.PrayerNotificationsWatchdogScheduler
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    companion object {
        // Temporary preview delay for checking the native Android splash.
        // Set to 0L to disable.
        private const val nativeSplashPreviewDelayMs = 0L

        private const val WATCHDOG_CHANNEL = "com.tilawa.app/prayer_watchdog"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        if (nativeSplashPreviewDelayMs > 0L) {
            val splashStartedAt = SystemClock.uptimeMillis()
            splashScreen.setKeepOnScreenCondition {
                SystemClock.uptimeMillis() - splashStartedAt < nativeSplashPreviewDelayMs
            }
        }
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == "com.tilawa.app.prayer.ACTION_OPEN_PRAYER_STATUS") {
            val prayerKey = intent.getStringExtra("prayer_key") ?: ""
            val id = intent.getIntExtra("notification_id", -1)
            // Construct a JSON-like payload that matches what PrayerAdhanNotificationService expects
            val payload = """{"prayer_key":"$prayerKey","notification_id":$id,"adhan_enabled":true}"""
            PrayerAdhanMethodChannel.notifyNotificationTapped(prayerKey, payload)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Register custom channels before super to ensure they are registered in tests
        // even if super.configureFlutterEngine throws (e.g. in Robolectric)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATCHDOG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensurePeriodicWatchdogScheduled" -> {
                        PrayerNotificationsWatchdogScheduler.enqueuePeriodic(applicationContext)
                        result.success(null)
                    }
                    "runPrayerNotificationWatchdogNow" -> {
                        PrayerNotificationsWatchdogScheduler.enqueueOneTime(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        PrayerAdhanMethodChannel.register(
            flutterEngine.dartExecutor.binaryMessenger,
            this,
        )
        
        super.configureFlutterEngine(flutterEngine)
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
