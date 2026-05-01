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
                
                analytics?.logEvent(PrayerEvents.SCHEDULE_STARTED, commonProps + mapOf(
                    "prayer_name" to name,
                    "is_adhan" to true
                ))

                if (id == null || triggerMs == null) {
                    result.error("BAD_ARGS", "id and triggerAtMillis required", null)
                } else {
                    val ok = scheduler.schedule(id, name, triggerMs)
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
                val triples = items.mapNotNull { entry ->
                    val id = (entry["id"] as? Number)?.toInt() ?: return@mapNotNull null
                    val name = (entry["name"] as? String).orEmpty()
                    val trigger = (entry["triggerAtMillis"] as? Number)?.toLong()
                        ?: return@mapNotNull null
                    Triple(id, name, trigger)
                }
                bootReceiver.persistPendingAlarms(triples)
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
                val delayMs = (arguments?.get("delayMs") as? Number)?.toLong() ?: 10000L
                val triggerAt = System.currentTimeMillis() + delayMs
                
                analytics?.logEvent(PrayerEvents.SCHEDULE_STARTED, commonProps + mapOf(
                    "prayer_name" to name,
                    "is_adhan" to true,
                    "is_manual_test" to true
                ))
                
                scheduler.schedule(id, name, triggerAt)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

interface BootReceiverProxy {
    fun persistPendingAlarms(entries: List<Triple<Int, String, Long>>)
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
