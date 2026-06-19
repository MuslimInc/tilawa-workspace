package com.tilawa.app.prayer
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

interface MethodResultProxy {
    fun success(result: Any?)
    fun error(errorCode: String, errorMessage: String?, errorDetails: Any?)
    fun notImplemented()
}

internal class MethodChannelLogic(
    private val scheduler: ExtendedAdhanSchedulerProxy,
    private val bootReceiver: BootReceiverProxy,
    private val storage: PrayerStorage,
    private val battery: BatteryOptimizationsProxy,
    private val analytics: PrayerAnalytics? = null
) {
    private fun persistNotificationLocation(locationName: String) {
        if (locationName.isNotBlank()) {
            storage.setLastNotificationLocationName(locationName)
        }
    }
    fun handleMethodCall(method: String, arguments: Map<String, Any?>?, result: MethodResultProxy) {
        val commonProps = mapOf(
            "notification_permission_granted" to scheduler.areNotificationsEnabled(),
            "exact_alarm_permission_granted" to scheduler.canScheduleExact()
        )

        when (method) {
            "scheduleAdhan" -> {
                val id = (arguments?.get("id") as? Number)?.toInt()
                val triggerMs = (arguments?.get("triggerAtMillis") as? Number)?.toLong()
                val name = (arguments?.get("prayerName") as? String) ?: ""
                val key = (arguments?.get("prayerKey") as? String) ?: name.lowercase()
                val sound = (arguments?.get("sound") as? String) ?: (if (key == "fajr") "adhan_fajr" else "adhan")
                val locationName = (arguments?.get("locationName") as? String).orEmpty()
                val languageCode = (arguments?.get("languageCode") as? String).orEmpty()
                
                analytics?.logEvent(PrayerEvents.ADHAN_SCHEDULED, mapOf(
                    "prayer_name" to name,
                    "prayer_key" to key,
                    "alarm_id" to id,
                    "scheduled_time_ms" to triggerMs,
                    "sound_name" to sound
                ))

                if (id == null || triggerMs == null) {
                    result.error("BAD_ARGS", "id and triggerAtMillis required", null)
                } else {
                    persistNotificationLocation(locationName)
                    val ok = scheduler.schedule(id, name, key, triggerMs, sound, locationName, languageCode)
                    if (ok) {
                        analytics?.logEvent(PrayerEvents.SCHEDULE_SUCCESS, commonProps + mapOf(
                            "prayer_name" to name,
                            "is_adhan" to true
                        ))
                    }
                    result.success(ok)
                }
            }
            "cancelAdhan" -> {
                val id = (arguments?.get("id") as? Number)?.toInt()
                val name = (arguments?.get("prayerName") as? String) ?: ""
                if (id == null) {
                    result.error("BAD_ARGS", "id required", null)
                } else {
                    analytics?.logEvent("adhan_alarm_cancelled", mapOf(
                        "prayer_name" to name,
                        "alarm_id" to id
                    ))
                    scheduler.cancel(id)
                    result.success(null)
                }
            }
            "cancelAllAdhans" -> {
                analytics?.logEvent("adhan_alarm_cancelled", mapOf("context" to "cancel_all"))
                scheduler.cancelAll()
                result.success(null)
            }
            "persistPendingAlarms" -> {
                @Suppress("UNCHECKED_CAST")
                val items = arguments?.get("alarms") as? List<Map<String, Any>> ?: emptyList()
                val alarms = items.mapNotNull { entry ->
                    val id = (entry["id"] as? Number)?.toInt() ?: return@mapNotNull null
                    val name = (entry["name"] as? String).orEmpty()
                    val key = (entry["key"] as? String).orEmpty()
                    val trigger = (entry["triggerAtMillis"] as? Number)?.toLong()
                        ?: return@mapNotNull null
                    val sound = (entry["sound"] as? String) ?: (if (key == "fajr") "adhan_fajr" else "adhan")
                    val locationName = (entry["locationName"] as? String).orEmpty()
                    val languageCode = (entry["languageCode"] as? String).orEmpty()
                    AlarmMetadata(id, name, key, trigger, sound, locationName, languageCode)
                }
                bootReceiver.persistPendingAlarms(alarms)
                alarms.firstOrNull { it.locationName.isNotBlank() }?.locationName?.let {
                    persistNotificationLocation(it)
                }
                result.success(null)
            }
            "clearPendingAlarms" -> {
                bootReceiver.clearPendingAlarms()
                result.success(null)
            }
            "consumeNeedsRescheduleAfterBoot" -> {
                val needs = storage.needsReschedule()
                if (needs) {
                    storage.setNeedsReschedule(false)
                }
                result.success(needs)
            }
            "markNeedsReschedule" -> {
                storage.setNeedsReschedule(true)
                result.success(null)
            }
            "isIgnoringBatteryOptimizations" -> {
                result.success(battery.isIgnoringBatteryOptimizations())
            }
            "requestIgnoreBatteryOptimizations" -> {
                battery.requestIgnoreBatteryOptimizations(result)
            }
            "manufacturer" -> result.success(android.os.Build.MANUFACTURER)
            "testAdhanNotification" -> {
                // Manual test button (Debug/Profile only on Flutter side)
                val id = (arguments?.get("id") as? Number)?.toInt() ?: 999999
                val name = (arguments?.get("name") as? String) ?: "test"
                val sound = (arguments?.get("sound") as? String) ?: "adhan"
                val delayMs = (arguments?.get("delayMs") as? Number)?.toLong() ?: 10000L
                val triggerAt = System.currentTimeMillis() + delayMs
                
                analytics?.logEvent(PrayerEvents.SCHEDULE_STARTED, commonProps + mapOf(
                    "prayer_name" to name,
                    "is_adhan" to true,
                    "is_manual_test" to true
                ))
                
                AdhanQALogger.logEvent(
                    context = scheduler.getContext(),
                    eventName = "QA_TEST_ADHAN_SCHEDULE_REQUESTED",
                    alarmId = id,
                    prayerName = name,
                    scheduledMs = triggerAt,
                    sound = sound
                )

                val ok = scheduler.schedule(id, name, "qa_test_adhan", triggerAt, sound)
                if (ok) {
                    AdhanQALogger.logEvent(
                        context = scheduler.getContext(),
                        eventName = "QA_TEST_ADHAN_SCHEDULED",
                        alarmId = id,
                        prayerName = name,
                        scheduledMs = triggerAt,
                        sound = sound
                    )
                }
                result.success(ok)
            }
            "setQALoggingEnabled" -> {
                val enabled = (arguments?.get("enabled") as? Boolean) ?: false
                AdhanQALogger.isEnabled = enabled
                result.success(null)
            }
            "logQAEvent" -> {
                val event = (arguments?.get("event") as? String) ?: "unknown"
                val prayer = (arguments?.get("prayer") as? String)
                val details = (arguments?.get("details") as? String)
                AdhanQALogger.logEvent(
                    context = scheduler.getContext(),
                    eventName = event,
                    source = "Flutter",
                    prayerName = prayer,
                    details = details
                )
                result.success(null)
            }
            "getQALogs" -> {
                result.success(AdhanQALogger.getLogs(scheduler.getContext()))
            }
            "clearQALogs" -> {
                AdhanQALogger.clearLogs(scheduler.getContext())
                result.success(null)
            }
            "playAdhanNow" -> {
                val id = (arguments?.get("id") as? Number)?.toInt()
                val name = (arguments?.get("prayerName") as? String) ?: ""
                val key = (arguments?.get("prayerKey") as? String) ?: name.lowercase()
                val sound = (arguments?.get("sound") as? String)
                    ?: (if (key == "fajr") "adhan_fajr" else "adhan")
                val locationName = (arguments?.get("locationName") as? String).orEmpty()
                val languageCode = (arguments?.get("languageCode") as? String).orEmpty()
                if (id == null) {
                    result.error("BAD_ARGS", "id required", null)
                } else {
                    persistNotificationLocation(locationName)
                    val context = scheduler.getContext()
                    val triggerMs = System.currentTimeMillis()
                    val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
                        action = AdhanPlaybackService.ACTION_PLAY
                        putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, id)
                        putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, name)
                        putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, key)
                        putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, triggerMs)
                        putExtra(AdhanScheduler.EXTRA_SOUND, sound)
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
                        analytics?.logEvent(
                            "adhan_play_now_started",
                            commonProps + mapOf(
                                "prayer_name" to name,
                                "prayer_key" to key,
                                "alarm_id" to id,
                            ),
                        )
                        result.success(true)
                    } catch (t: Throwable) {
                        Log.e("MethodChannelLogic", "playAdhanNow failed", t)
                        result.error("PLAY_ADHAN_NOW_FAILED", t.message, null)
                    }
                }
            }
            "stopAdhan" -> {
                val context = scheduler.getContext()
                val stopIntent = Intent(AdhanPlaybackService.ACTION_STOP)
                stopIntent.component = ComponentName(
                    context.packageName,
                    AdhanPlaybackService::class.java.name
                )
                Log.d("MethodChannelLogic", "STOP_ADHAN_FROM_APP_REQUESTED")
                try {
                    context.startService(stopIntent)
                    analytics?.logEvent("adhan_stop_tapped_from_app")
                    Log.d("MethodChannelLogic", "STOP_ADHAN_FROM_APP_NATIVE_SUCCESS")
                    result.success(true)
                } catch (t: Throwable) {
                    Log.e("MethodChannelLogic", "STOP_ADHAN_FROM_APP_NATIVE_FAILED", t)
                    result.error("STOP_ADHAN_FAILED", t.message, null)
                }
            }
            "isAdhanPlaying" -> {
                result.success(AdhanPlaybackService.isRunning)
            }
            "getActiveAdhanPayload" -> {
                val payload = AdhanPlaybackService.activePayload
                if (payload == null) {
                    result.success(null)
                } else {
                    result.success(mapOf(
                        "prayer_name" to payload.prayerName,
                        "prayer_key" to payload.prayerKey,
                        "sound_name" to payload.sound,
                        "scheduled_time_ms" to payload.scheduledMs,
                        "notification_id" to payload.notificationId,
                        "adhan_enabled" to true,
                        "is_adhan_playing" to true,
                        "location_name" to payload.locationName,
                        "language_code" to payload.languageCode,
                    ))
                }
            }
            else -> result.notImplemented()
        }
    }
}

interface BootReceiverProxy {
    fun persistPendingAlarms(entries: List<AlarmMetadata>)
    fun clearPendingAlarms()
}

interface BatteryOptimizationsProxy {
    fun isIgnoringBatteryOptimizations(): Boolean
    fun requestIgnoreBatteryOptimizations(result: MethodResultProxy)
}

interface ExtendedAdhanSchedulerProxy : AdhanSchedulerProxy {
    fun cancel(id: Int)
    fun cancelAll()
}
