package com.tilawa.app

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.ryanheise.audioservice.AudioServiceActivity
import com.tilawa.app.prayer.AdhanScheduler
import com.tilawa.app.prayer.PrayerAdhanMethodChannel
import com.tilawa.app.prayer.PrayerNotificationsWatchdogScheduler
import androidx.annotation.VisibleForTesting
import io.flutter.embedding.android.RenderMode
import io.sentry.Sentry
import io.sentry.flutter.SentryFlutterPlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val WATCHDOG_CHANNEL = "com.tilawa.app/prayer_watchdog"
        private const val LAUNCH_SPLASH_CHANNEL = "com.tilawa.app/launch_splash"
        private const val APP_CONTEXT_CHANNEL = "com.tilawa.app/app_context"
        private const val GOOGLE_SIGN_IN_CHANNEL = "com.tilawa.app/google_sign_in"
        const val ACTION_OPEN_PRAYER_STATUS =
            "com.tilawa.app.prayer.ACTION_OPEN_PRAYER_STATUS"
        private const val TAG = "MainActivity"
        private const val GSIGNIN_TAG = "TilawaGSignIn"
        private const val FIRST_FRAME_TAG = "FirstFrame"

        // Failsafe: must outlast the Dart-side LaunchFirstFrameGate failsafe
        // (3s) so the graceful "ready" path wins on healthy launches. If Dart
        // never sends "ready" (engine wedge, bad patch, crash before runApp),
        // the splash is force-dismissed instead of holding the user forever.
        private const val LAUNCH_SPLASH_FAILSAFE_MS = 6_000L

        @Volatile
        var keepLaunchSplashOnScreen: Boolean = true

        /** Updated on each [configureFlutterEngine]; used by credential UI lifecycle. */
        @Volatile
        var invokeCredentialUiDismissed: (() -> Unit)? = null
    }

    private fun firstFrameLog(message: String) {
        Log.d(FIRST_FRAME_TAG, message)
    }

    private var renderMode: RenderMode = RenderMode.surface

    override fun onCreate(savedInstanceState: Bundle?) {
        renderMode = resolveRenderMode(intent)
        Log.d(
            TAG,
            "MAIN_ACTIVITY_ON_CREATE_INTENT action=${intent?.action} extras=${intent?.extras?.keySet()} renderMode=$renderMode"
        )
        firstFrameLog("MainActivity.onCreate installSplashScreen")
        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { keepLaunchSplashOnScreen }
        splashScreen.setOnExitAnimationListener { splashScreenView ->
            firstFrameLog("splash exit animation → remove() (no fade)")
            splashScreenView.remove()
        }
        Handler(Looper.getMainLooper()).postDelayed({
            if (keepLaunchSplashOnScreen) {
                Log.w(TAG, "Launch splash failsafe fired — Flutter never sent 'ready'")
                firstFrameLog("FAILSAFE: forcing keepLaunchSplashOnScreen=false")
                keepLaunchSplashOnScreen = false
            }
        }, LAUNCH_SPLASH_FAILSAFE_MS)
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
        registerAppMethodChannels(flutterEngine)
        if (TranssionOemPolicy.isTranssionDevice()) {
            TranssionCredentialUiLifecycle.ensureRegistered(application)
            invokeCredentialUiDismissed = {
                MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    GOOGLE_SIGN_IN_CHANNEL,
                ).invokeMethod("onCredentialUiDismissed", null)
            }
        }
        // Belt-and-suspenders for cold start; hot restart is restored from Dart
        // main() before SentryFlutter.init.
        restoreSentryFlutterApplicationContext()
    }

    @VisibleForTesting
    internal fun registerAppMethodChannels(flutterEngine: FlutterEngine) {
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CONTEXT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstallerPackageName" -> {
                        result.success(readInstallerPackageName())
                    }
                    "restoreSentryApplicationContext" -> {
                        restoreSentryFlutterApplicationContext()
                        result.success(null)
                    }
                    "isSentryNativeSdkInitialized" -> {
                        result.success(Sentry.isEnabled())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Hot restart detaches the Sentry plugin and nulls its static
     * [SentryFlutterPlugin] applicationContext before Dart main() re-runs.
     * Re-apply it so JNI init can succeed without onAttachedToEngine (not
     * called again on hot restart).
     */
    private fun restoreSentryFlutterApplicationContext() {
        val appContext = applicationContext ?: return
        if (SentryFlutterPlugin.getApplicationContext() != null) {
            return
        }
        try {
            val contextField =
                SentryFlutterPlugin::class.java.getDeclaredField("applicationContext")
            contextField.isAccessible = true
            contextField.set(null, appContext)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to restore Sentry applicationContext", e)
        }
    }

    private fun readInstallerPackageName(): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstallerPackageName(packageName)
        }
    }

    override fun onResume() {
        super.onResume()
        if (TranssionOemPolicy.isTranssionDevice()) {
            Log.d(
                GSIGNIN_TAG,
                "H1 MainActivity.onResume " +
                    "renderMode=$renderMode isFinishing=$isFinishing",
            )
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, GOOGLE_SIGN_IN_CHANNEL)
                    .invokeMethod("onMainActivityResumed", null)
            }
        }
    }

    override fun getRenderMode(): RenderMode = renderMode

    /**
     * Notification cold starts can launch through the lockscreen/shade path.
     * [RenderMode.surface] delays the first Android draw until the first
     * Flutter frame and can deadlock that transition (persistent black screen).
     * [RenderMode.texture] avoids the pre-draw gate for that path only.
     *
     * Transsion ROMs (Infinix, Tecno, Itel) also need [RenderMode.texture] so
     * Credential Manager / Play Services sign-in UI is not hidden behind the
     * Flutter surface (otherwise [authenticate] hangs until timeout).
     *
     * Other launches use [RenderMode.surface].
     */
    private fun resolveRenderMode(intent: Intent?): RenderMode {
        if (intent?.action == ACTION_OPEN_PRAYER_STATUS) {
            return RenderMode.texture
        }
        if (TranssionOemPolicy.isTranssionDevice()) {
            Log.d(
                GSIGNIN_TAG,
                "H5 onCreate renderMode=texture " +
                    "manufacturer=${Build.MANUFACTURER} brand=${Build.BRAND}",
            )
            return RenderMode.texture
        }
        return RenderMode.surface
    }
}
