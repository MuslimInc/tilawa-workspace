package com.tilawa.app.prayer

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

internal class PrayerNotificationsWatchdogWorker(
    appContext: Context,
    workerParams: WorkerParameters,
) : Worker(appContext, workerParams) {
    override fun doWork(): Result {
        val analytics = FirebasePrayerAnalytics(applicationContext)
        analytics.logEvent(PrayerEvents.WATCHDOG_TRIGGERED)
        Log.d(TAG, "Prayer notification watchdog started")

        val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (!nm.areNotificationsEnabled()) {
            Log.i(TAG, "Notification permission revoked, canceling all native alarms")
            AdhanScheduler.cancelAll(applicationContext)
        }

        val completion = CountDownLatch(1)
        val workerResult = AtomicReference<Result>(Result.retry())
        val mainHandler = Handler(Looper.getMainLooper())
        val engineRef = AtomicReference<FlutterEngine?>()

        mainHandler.post {
            try {
                val appContext = applicationContext
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(appContext)
                loader.ensureInitializationComplete(appContext, null)

                val engine = FlutterEngine(appContext)
                engineRef.set(engine)
                GeneratedPluginRegistrant.registerWith(engine)
                PrayerAdhanMethodChannel.register(
                    engine.dartExecutor.binaryMessenger,
                    appContext,
                )

                val watchdogLogic = WatchdogLogic()

                MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    BACKGROUND_CHANNEL,
                ).setMethodCallHandler { call, result ->
                    when (call.method) {
                        "watchdogComplete" -> {
                            val success = call.argument<Boolean>("success") ?: false
                            val retryable = call.argument<Boolean>("retryable") ?: false
                            val message = call.argument<String>("message")
                            val action = call.argument<String>("action")
                            
                            Log.d(
                                TAG,
                                "Watchdog completed success=$success retryable=$retryable " +
                                    "action=$action message=$message",
                            )
                            
                            if (success) {
                                analytics.logEvent(PrayerEvents.WATCHDOG_COMPLETED, mapOf("action" to action))
                            } else {
                                analytics.logEvent(PrayerEvents.WATCHDOG_FAILED, mapOf("retryable" to retryable, "message" to message))
                            }

                            workerResult.set(
                                watchdogLogic.handleComplete(success, retryable, message, action)
                            )
                            result.success(null)
                            completion.countDown()
                        }
                        "watchdogLog" -> {
                            Log.d(TAG, call.argument<String>("message").orEmpty())
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }

                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        loader.findAppBundlePath(),
                        DART_ENTRYPOINT,
                    ),
                )
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to start watchdog Flutter engine", t)
                val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                analytics.logError(
                    "Failed to start watchdog Flutter engine", 
                    t,
                    mapOf(
                        "exact_alarm_permission_granted" to AdhanScheduler.canScheduleExact(applicationContext),
                        "notification_permission_granted" to nm.areNotificationsEnabled(),
                        "device_manufacturer" to android.os.Build.MANUFACTURER,
                        "fallback_used" to false
                    )
                )
                analytics.logEvent(PrayerEvents.WATCHDOG_FAILED, mapOf("reason" to "engine_start_error"))
                workerResult.set(Result.retry())
                completion.countDown()
            }
        }

        val completed = completion.await(WATCHDOG_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        mainHandler.post {
            try {
                engineRef.getAndSet(null)?.destroy()
            } catch (t: Throwable) {
                Log.w(TAG, "Failed to destroy watchdog Flutter engine", t)
            }
        }

        if (!completed) {
            Log.w(TAG, "Prayer notification watchdog timed out")
            val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            analytics.logError(
                "Prayer notification watchdog timed out",
                null,
                mapOf(
                    "timeout_seconds" to WATCHDOG_TIMEOUT_SECONDS,
                    "exact_alarm_permission_granted" to AdhanScheduler.canScheduleExact(applicationContext),
                    "notification_permission_granted" to nm.areNotificationsEnabled(),
                    "device_manufacturer" to Build.MANUFACTURER,
                    "fallback_used" to false
                )
            )
            analytics.logEvent(PrayerEvents.WATCHDOG_TIMEOUT)
            return Result.retry()
        }

        return workerResult.get()
    }

    companion object {
        private const val TAG = "PrayerWatchdog"
        private const val BACKGROUND_CHANNEL =
            "com.tilawa.app/prayer_watchdog_background"
        private const val DART_ENTRYPOINT = "prayerNotificationWatchdogEntrypoint"
        private const val WATCHDOG_TIMEOUT_SECONDS = 15L
    }
}
