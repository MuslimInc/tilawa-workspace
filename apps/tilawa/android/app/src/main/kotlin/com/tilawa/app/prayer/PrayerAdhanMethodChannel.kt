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

internal object PrayerAdhanMethodChannel {
    private const val CHANNEL = "com.tilawa.app/prayer_adhan"

    private var logic: MethodChannelLogic? = null

    @VisibleForTesting
    fun setLogic(logic: MethodChannelLogic?) {
        this.logic = logic
    }

    fun register(messenger: BinaryMessenger, context: Context) {
        val appContext = context.applicationContext
        val storage = DefaultPrayerStorage(appContext)
        val activeLogic = logic ?: MethodChannelLogic(
            scheduler = object : ExtendedAdhanSchedulerProxy {
                override fun canScheduleExact() = AdhanScheduler.canScheduleExact(appContext)
                override fun areNotificationsEnabled(): Boolean {
                    val nm = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    return nm.areNotificationsEnabled()
                }
                override fun schedule(id: Int, name: String, triggerMs: Long) =
                    AdhanScheduler.schedule(appContext, id, name, triggerMs)
                override fun cancel(id: Int) =
                    AdhanScheduler.cancel(appContext, id)
                override fun cancelAll() =
                    AdhanScheduler.cancelAll(appContext)
            },
            bootReceiver = object : BootReceiverProxy {
                override fun persistPendingAlarms(entries: List<Triple<Int, String, Long>>) =
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
                    requestIgnoreBatteryOptimizationsInternal(context, result)
                }
            },
            analytics = FirebasePrayerAnalytics(appContext)
        )

        MethodChannel(messenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val proxy = object : MethodResultProxy {
                    override fun success(res: Any?) = result.success(res)
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) =
                        result.error(errorCode, errorMessage, errorDetails)
                    override fun notImplemented() = result.notImplemented()
                }
                @Suppress("UNCHECKED_CAST")
                activeLogic.handleMethodCall(call.method, call.arguments as? Map<String, Any?>, proxy)
            }
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
