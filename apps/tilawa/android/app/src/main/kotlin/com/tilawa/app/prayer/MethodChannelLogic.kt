package com.tilawa.app.prayer

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
                val sound = (arguments?.get("sound") as? String) ?: (if (name.lowercase() == "fajr") "adhan_fajr" else "adhan")
                
                analytics?.logEvent(PrayerEvents.SCHEDULE_STARTED, commonProps + mapOf(
                    "prayer_name" to name,
                    "is_adhan" to true
                ))

                if (id == null || triggerMs == null) {
                    result.error("BAD_ARGS", "id and triggerAtMillis required", null)
                } else {
                    val ok = scheduler.schedule(id, name, triggerMs, sound)
                    if (ok) {
                        analytics?.logEvent(PrayerEvents.SCHEDULE_SUCCESS, commonProps + mapOf(
                            "prayer_name" to name,
                            "delay_seconds" to (triggerMs - System.currentTimeMillis()) / 1000
                        ))
                    } else {
                        analytics?.logEvent(PrayerEvents.SCHEDULE_FAILED, commonProps + mapOf(
                            "prayer_name" to name,
                            "reason" to "permission_denied"
                        ))
                    }
                    result.success(ok)
                }
            }
            "cancelAdhan" -> {
                val id = (arguments?.get("id") as? Number)?.toInt()
                if (id == null) {
                    result.error("BAD_ARGS", "id required", null)
                } else {
                    scheduler.cancel(id)
                    result.success(null)
                }
            }
            "cancelAllAdhans" -> {
                scheduler.cancelAll()
                result.success(null)
            }
            "persistPendingAlarms" -> {
                @Suppress("UNCHECKED_CAST")
                val items = arguments?.get("alarms") as? List<Map<String, Any>> ?: emptyList()
                val alarms = items.mapNotNull { entry ->
                    val id = (entry["id"] as? Number)?.toInt() ?: return@mapNotNull null
                    val name = (entry["name"] as? String).orEmpty()
                    val trigger = (entry["triggerAtMillis"] as? Number)?.toLong()
                        ?: return@mapNotNull null
                    val sound = (entry["sound"] as? String) ?: (if (name.lowercase() == "fajr") "adhan_fajr" else "adhan")
                    AlarmMetadata(id, name, trigger, sound)
                }
                bootReceiver.persistPendingAlarms(alarms)
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

                val ok = scheduler.schedule(id, name, triggerAt, sound)
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
