package com.tilawa.app.prayer

import io.mockk.*
import org.junit.Test
import org.junit.Assert.*

class MethodChannelLogicTest {
    private val mockScheduler = mockk<ExtendedAdhanSchedulerProxy>(relaxed = true)
    private val mockBootReceiver = mockk<BootReceiverProxy>(relaxed = true)
    private val mockStorage = mockk<PrayerStorage>(relaxed = true)
    private val mockBattery = mockk<BatteryOptimizationsProxy>(relaxed = true)
    private val mockAnalytics = mockk<PrayerAnalytics>(relaxed = true)
    private val logic = MethodChannelLogic(mockScheduler, mockBootReceiver, mockStorage, mockBattery, mockAnalytics)
    private val mockResult = mockk<MethodResultProxy>(relaxed = true)

    @Test
    fun `scheduleAdhan logs events`() {
        val args = mapOf("id" to 1, "triggerAtMillis" to 1000L, "prayerName" to "fajr")
        every { mockScheduler.schedule(any(), any(), any(), any(), any()) } returns true
        every { mockScheduler.canScheduleExact() } returns true
        
        logic.handleMethodCall("scheduleAdhan", args, mockResult)
        
        verify { mockAnalytics.logEvent(PrayerEvents.ADHAN_SCHEDULED, any()) }
        verify { mockAnalytics.logEvent(PrayerEvents.SCHEDULE_SUCCESS, any()) }
    }

    @Test
    fun `scheduleAdhan success`() {
        val args = mapOf("id" to 1, "triggerAtMillis" to 1000L, "prayerName" to "fajr", "prayerKey" to "fajr")
        every { mockScheduler.schedule(1, "fajr", "fajr", 1000L, "adhan_fajr") } returns true
        
        logic.handleMethodCall("scheduleAdhan", args, mockResult)
        
        verify { mockScheduler.schedule(1, "fajr", "fajr", 1000L, "adhan_fajr") }
        verify { mockResult.success(true) }
    }

    @Test
    fun `scheduleAdhan missing args`() {
        val args = mapOf("id" to 1) // missing triggerAtMillis
        
        logic.handleMethodCall("scheduleAdhan", args, mockResult)
        
        verify { mockResult.error("BAD_ARGS", any(), any()) }
    }

    @Test
    fun `cancelAdhan`() {
        val args = mapOf("id" to 1)
        logic.handleMethodCall("cancelAdhan", args, mockResult)
        
        verify { mockScheduler.cancel(1) }
        verify { mockResult.success(null) }
    }

    @Test
    fun `cancelAllAdhans`() {
        logic.handleMethodCall("cancelAllAdhans", null, mockResult)
        verify { mockScheduler.cancelAll() }
        verify { mockResult.success(null) }
    }

    @Test
    fun `persistPendingAlarms`() {
        val alarms = listOf(
            mapOf("id" to 1, "name" to "fajr", "triggerAtMillis" to 1000L)
        )
        val args = mapOf("alarms" to alarms)
        
        logic.handleMethodCall("persistPendingAlarms", args, mockResult)
        
        verify { mockBootReceiver.persistPendingAlarms(any()) }
        verify { mockResult.success(null) }
    }

    @Test
    fun `consumeNeedsRescheduleAfterBoot`() {
        every { mockStorage.needsReschedule() } returns true
        
        logic.handleMethodCall("consumeNeedsRescheduleAfterBoot", null, mockResult)
        
        verify { mockStorage.setNeedsReschedule(false) }
        verify { mockResult.success(true) }
    }

    @Test
    fun `isIgnoringBatteryOptimizations`() {
        every { mockBattery.isIgnoringBatteryOptimizations() } returns true
        
        logic.handleMethodCall("isIgnoringBatteryOptimizations", null, mockResult)
        
        verify { mockResult.success(true) }
    }

    @Test
    fun `requestIgnoreBatteryOptimizations`() {
        logic.handleMethodCall("requestIgnoreBatteryOptimizations", null, mockResult)
        verify { mockBattery.requestIgnoreBatteryOptimizations(mockResult) }
    }

    @Test
    fun `consumeNeedsRescheduleAfterBoot returns false when not needed`() {
        every { mockStorage.needsReschedule() } returns false
        
        logic.handleMethodCall("consumeNeedsRescheduleAfterBoot", null, mockResult)
        
        verify(exactly = 0) { mockStorage.setNeedsReschedule(any()) }
        verify { mockResult.success(false) }
    }

    @Test
    fun `persistPendingAlarms handles null args`() {
        logic.handleMethodCall("persistPendingAlarms", null, mockResult)
        verify { mockBootReceiver.persistPendingAlarms(emptyList()) }
        verify { mockResult.success(null) }
    }

    @Test
    fun `persistPendingAlarms handles null alarms list`() {
        logic.handleMethodCall("persistPendingAlarms", mapOf("alarms" to null), mockResult)
        verify { mockBootReceiver.persistPendingAlarms(emptyList()) }
    }

    @Test
    fun `clearPendingAlarms`() {
        logic.handleMethodCall("clearPendingAlarms", null, mockResult)
        verify { mockBootReceiver.clearPendingAlarms() }
        verify { mockResult.success(null) }
    }

    @Test
    fun `cancelAdhan missing id`() {
        logic.handleMethodCall("cancelAdhan", null, mockResult)
        verify { mockResult.error("BAD_ARGS", any(), any()) }
    }

    @Test
    fun `persistPendingAlarms invalid triggerAtMillis`() {
        val alarms = listOf(mapOf("id" to 1, "name" to "fajr")) // missing triggerAtMillis
        logic.handleMethodCall("persistPendingAlarms", mapOf("alarms" to alarms), mockResult)
        verify { mockBootReceiver.persistPendingAlarms(emptyList()) }
    }

    @Test
    fun `manufacturer`() {
        logic.handleMethodCall("manufacturer", null, mockResult)
        verify { mockResult.success(any()) }
    }

    @Test
    fun `testAdhanNotification success`() {
        val args = mapOf("id" to 999999, "name" to "qa_test_adhan", "delayMs" to 1000L)
        every { mockScheduler.schedule(any(), any(), any(), any(), any()) } returns true
        
        logic.handleMethodCall("testAdhanNotification", args, mockResult)
        
        verify { mockScheduler.schedule(999999, "qa_test_adhan", "qa_test_adhan", any(), "adhan") }
        verify { mockResult.success(true) }
    }

    @Test
    fun `unknown method`() {
        logic.handleMethodCall("unknown", null, mockResult)
        verify { mockResult.notImplemented() }
    }
}
