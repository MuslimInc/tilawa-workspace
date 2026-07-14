package com.tilawa.app.prayer

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import androidx.annotation.VisibleForTesting

internal object PrayerAdhanMethodChannel {
    private const val CHANNEL = "com.tilawa.app/prayer_adhan"
    private const val TAG = "PrayerAdhanMethodChannel"

    private var logic: MethodChannelLogic? = null
    private var methodChannel: MethodChannel? = null
    private var pendingTap: Pair<String, String>? = null
    private var isDebuggable: Boolean = false

    private fun logDebug(message: String) {
        if (isDebuggable) Log.d(TAG, message)
    }

    @VisibleForTesting
    fun setLogic(logic: MethodChannelLogic?) {
        this.logic = logic
    }

    @VisibleForTesting
    fun resetForTesting() {
        methodChannel = null
        pendingTap = null
    }

    fun register(messenger: BinaryMessenger, context: Context) {
        val appContext = context.applicationContext
        isDebuggable =
            (appContext.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
        val storage = DefaultPrayerStorage(appContext)
        val activeLogic = logic ?: MethodChannelLogic(
            scheduler = object : ExtendedAdhanSchedulerProxy {
                override fun getContext() = appContext
                override fun canScheduleExact() = AdhanScheduler.canScheduleExact(appContext)
                override fun areNotificationsEnabled(): Boolean {
                    val nm = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    return nm.areNotificationsEnabled()
                }
                override fun schedule(
                    id: Int,
                    name: String,
                    key: String,
                    triggerMs: Long,
                    sound: String,
                    locationName: String,
                    languageCode: String,
                ) = AdhanScheduler.schedule(
                    appContext,
                    id,
                    name,
                    key,
                    triggerMs,
                    sound,
                    locationName,
                    languageCode,
                )
                override fun cancel(id: Int) =
                    AdhanScheduler.cancel(appContext, id)
                override fun cancelAll() =
                    AdhanScheduler.cancelAll(appContext)
            },
            bootReceiver = object : BootReceiverProxy {
                override fun persistPendingAlarms(entries: List<AlarmMetadata>) =
                    PrayerBootReceiver.persistPendingAlarms(appContext, entries)
                override fun clearPendingAlarms() =
                    PrayerBootReceiver.clearPendingAlarms(appContext)
            },
            storage = storage,
            battery = object : BatteryOptimizationsProxy {
                override fun isIgnoringBatteryOptimizations(): Boolean {
                    val pm = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
                    return pm.isIgnoringBatteryOptimizations(appContext.packageName)
                }
                override fun requestIgnoreBatteryOptimizations(result: MethodResultProxy) {
                    // Battery whitelist dialog temporarily disabled.
                    // requestIgnoreBatteryOptimizationsInternal(context, result)
                    result.success(false)
                }
            },
            analytics = FirebasePrayerAnalytics(appContext)
        )

        val mc = MethodChannel(messenger, CHANNEL)
        mc.setMethodCallHandler { call, result ->
            if (call.method == "consumePendingNotificationTap") {
                val tap = pendingTap
                if (tap == null) {
                    result.success(null)
                } else {
                    pendingTap = null
                    logDebug("METHOD_CHANNEL_TAP_FLUSHED prayerKey=${tap.first}")
                    result.success(
                        mapOf(
                            "prayer_key" to tap.first,
                            "payload" to tap.second
                        )
                    )
                }
                return@setMethodCallHandler
            }

            if (call.method == "ackNotificationTap") {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?>
                val payload = args?.get("payload") as? String
                if (payload != null && pendingTap?.second == payload) {
                    logDebug(
                        "METHOD_CHANNEL_TAP_FLUSHED source=ack prayerKey=${pendingTap?.first}"
                    )
                    pendingTap = null
                }
                result.success(null)
                return@setMethodCallHandler
            }

            val proxy = object : MethodResultProxy {
                override fun success(res: Any?) = result.success(res)
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) =
                    result.error(errorCode, errorMessage, errorDetails)
                override fun notImplemented() = result.notImplemented()
            }
            @Suppress("UNCHECKED_CAST")
            activeLogic.handleMethodCall(call.method, call.arguments as? Map<String, Any?>, proxy)
        }
        this.methodChannel = mc
    }

    fun notifyNotificationTapped(prayerKey: String, payload: String) {
        logDebug("METHOD_CHANNEL_TAP_RECEIVED prayerKey=$prayerKey")
        pendingTap = Pair(prayerKey, payload)
        val mc = methodChannel
        if (mc == null) {
            logDebug("METHOD_CHANNEL_TAP_BUFFERED reason=no_channel prayerKey=$prayerKey")
            return
        }
        logDebug(
            "METHOD_CHANNEL_TAP_BUFFERED reason=awaiting_dart_ack prayerKey=$prayerKey"
        )
        mc.invokeMethod(
            "onNotificationTapped",
            mapOf(
                "prayer_key" to prayerKey,
                "payload" to payload
            )
        )
    }

    private fun requestIgnoreBatteryOptimizationsInternal(
        context: Context,
        result: MethodResultProxy,
    ) {
        val appContext = context.applicationContext
        val pm = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (pm.isIgnoringBatteryOptimizations(appContext.packageName)) {
            result.success(true)
            return
        }

        try {
            val intent = Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:${appContext.packageName}"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(false)
        } catch (t: Throwable) {
            try {
                context.startActivity(
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                result.success(false)
            } catch (t2: Throwable) {
                result.error("UNAVAILABLE", t2.message, null)
            }
        }
    }
}

