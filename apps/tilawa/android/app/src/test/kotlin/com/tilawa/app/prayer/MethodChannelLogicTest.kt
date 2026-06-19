package com.tilawa.app.prayer

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import io.mockk.*
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
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
        val args = mapOf(
            "id" to 1,
            "triggerAtMillis" to 1000L,
            "prayerName" to "fajr",
            "prayerKey" to "fajr",
            "locationName" to "Cairo",
            "languageCode" to "ar",
        )
        every {
            mockScheduler.schedule(1, "fajr", "fajr", 1000L, "adhan_fajr", "Cairo", "ar")
        } returns true

        logic.handleMethodCall("scheduleAdhan", args, mockResult)

        verify {
            mockScheduler.schedule(1, "fajr", "fajr", 1000L, "adhan_fajr", "Cairo", "ar")
        }
        verify { mockStorage.setLastNotificationLocationName("Cairo") }
        verify { mockResult.success(true) }
    }

    @Test
    fun `scheduleAdhan persists location when provided`() {
        val args = mapOf(
            "id" to 2,
            "triggerAtMillis" to 2000L,
            "prayerName" to "dhuhr",
            "locationName" to "Al Isaweyah",
        )
        every { mockScheduler.schedule(any(), any(), any(), any(), any(), any(), any()) } returns true

        logic.handleMethodCall("scheduleAdhan", args, mockResult)

        verify { mockStorage.setLastNotificationLocationName("Al Isaweyah") }
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
    fun `stopAdhan starts service stop action`() {
        val context = mockk<Context>(relaxed = true)
        val intentSlot = slot<Intent>()
        every { mockScheduler.getContext() } returns context
        every { context.packageName } returns "com.tilawa.app"
        every { context.startService(capture(intentSlot)) } returns null

        logic.handleMethodCall("stopAdhan", null, mockResult)

        assertEquals(AdhanPlaybackService.ACTION_STOP, intentSlot.captured.action)
        verify { mockResult.success(true) }
    }

    @Test
    fun `persistPendingAlarms persists location from first alarm entry`() {
        val alarms = listOf(
            mapOf(
                "id" to 1,
                "name" to "fajr",
                "key" to "fajr",
                "triggerAtMillis" to 1000L,
                "locationName" to "Cairo",
                "languageCode" to "ar",
            ),
        )

        logic.handleMethodCall("persistPendingAlarms", mapOf("alarms" to alarms), mockResult)

        verify { mockBootReceiver.persistPendingAlarms(any()) }
        verify { mockStorage.setLastNotificationLocationName("Cairo") }
    }

    @Test
    fun `playAdhanNow starts service with location and language extras`() {
        mockkStatic(ContextCompat::class)
        try {
            val context = mockk<Context>(relaxed = true)
            val intentSlot = slot<Intent>()
            every { mockScheduler.getContext() } returns context
            every { context.packageName } returns "com.tilawa.app"
            every {
                ContextCompat.startForegroundService(context, capture(intentSlot))
            } just Runs

            val args = mapOf(
                "id" to 2001,
                "prayerName" to "fajr",
                "prayerKey" to "fajr",
                "locationName" to "Cairo",
                "languageCode" to "ar",
            )

            logic.handleMethodCall("playAdhanNow", args, mockResult)

            assertEquals(AdhanPlaybackService.ACTION_PLAY, intentSlot.captured.action)
            assertEquals("Cairo", intentSlot.captured.getStringExtra(AdhanScheduler.EXTRA_LOCATION_NAME))
            assertEquals("ar", intentSlot.captured.getStringExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE))
            verify { mockStorage.setLastNotificationLocationName("Cairo") }
            verify { mockResult.success(true) }
        } finally {
            unmockkStatic(ContextCompat::class)
        }
    }

    @Test
    fun `playAdhanNow missing id returns error`() {
        logic.handleMethodCall("playAdhanNow", mapOf("prayerName" to "fajr"), mockResult)
        verify { mockResult.error("BAD_ARGS", "id required", null) }
    }

    @Test
    fun `getActiveAdhanPayload includes location and language when present`() {
        AdhanPlaybackService.setActivePayloadForTest(
            AdhanPlaybackService.ActiveAdhanPayload(
                prayerName = "fajr",
                prayerKey = "fajr",
                sound = "adhan_fajr",
                scheduledMs = 1700000000000L,
                notificationId = 12345,
                locationName = "Cairo",
                languageCode = "ar",
            ),
        )

        val resultSlot = slot<Any>()
        every { mockResult.success(capture(resultSlot)) } returns Unit

        logic.handleMethodCall("getActiveAdhanPayload", null, mockResult)

        @Suppress("UNCHECKED_CAST")
        val captured = resultSlot.captured as Map<String, Any?>
        assertEquals("Cairo", captured["location_name"])
        assertEquals("ar", captured["language_code"])

        AdhanPlaybackService.setActivePayloadForTest(null)
    }

    @Test
    fun `markNeedsReschedule`() {
        logic.handleMethodCall("markNeedsReschedule", null, mockResult)
        verify { mockStorage.setNeedsReschedule(true) }
        verify { mockResult.success(null) }
    }

    @Test
    fun `isAdhanPlaying returns service running state`() {
        AdhanPlaybackService.setActivePayloadForTest(null)
        logic.handleMethodCall("isAdhanPlaying", null, mockResult)
        verify { mockResult.success(false) }
    }

    @Test
    fun `unknown method`() {
        logic.handleMethodCall("unknown", null, mockResult)
        verify { mockResult.notImplemented() }
    }

    @Test
    fun `getActiveAdhanPayload returns null when nothing playing`() {
        AdhanPlaybackService.setActivePayloadForTest(null)

        logic.handleMethodCall("getActiveAdhanPayload", null, mockResult)

        verify { mockResult.success(null) }
    }

    @Test
    fun `getActiveAdhanPayload returns map with payload fields when playing`() {
        AdhanPlaybackService.setActivePayloadForTest(
            AdhanPlaybackService.ActiveAdhanPayload(
                prayerName = "fajr",
                prayerKey = "fajr",
                sound = "adhan_fajr",
                scheduledMs = 1700000000000L,
                notificationId = 12345,
            )
        )

        val resultSlot = slot<Any>()
        every { mockResult.success(capture(resultSlot)) } returns Unit

        logic.handleMethodCall("getActiveAdhanPayload", null, mockResult)

        @Suppress("UNCHECKED_CAST")
        val captured = resultSlot.captured as Map<String, Any?>
        assertEquals("fajr", captured["prayer_name"])
        assertEquals("fajr", captured["prayer_key"])
        assertEquals("adhan_fajr", captured["sound_name"])
        assertEquals(1700000000000L, captured["scheduled_time_ms"])
        assertEquals(12345, captured["notification_id"])
        assertEquals(true, captured["adhan_enabled"])
        assertEquals(true, captured["is_adhan_playing"])

        AdhanPlaybackService.setActivePayloadForTest(null)
    }

    @Test
    fun `scheduleAdhan does not log success when scheduler returns false`() {
        val args = mapOf("id" to 1, "triggerAtMillis" to 1000L, "prayerName" to "fajr")
        every { mockScheduler.schedule(any(), any(), any(), any(), any(), any(), any()) } returns false

        logic.handleMethodCall("scheduleAdhan", args, mockResult)

        verify(exactly = 0) { mockAnalytics.logEvent(PrayerEvents.SCHEDULE_SUCCESS, any()) }
        verify { mockResult.success(false) }
    }

    @Test
    fun `setQALoggingEnabled toggles logger flag`() {
        logic.handleMethodCall("setQALoggingEnabled", mapOf("enabled" to true), mockResult)
        assertTrue(AdhanQALogger.isEnabled)
        logic.handleMethodCall("setQALoggingEnabled", mapOf("enabled" to false), mockResult)
        assertFalse(AdhanQALogger.isEnabled)
        verify(exactly = 2) { mockResult.success(null) }
    }

    @Test
    fun `logQAEvent forwards to logger`() {
        val context = mockk<Context>(relaxed = true)
        every { mockScheduler.getContext() } returns context

        logic.handleMethodCall(
            "logQAEvent",
            mapOf("event" to "TEST_EVENT", "prayer" to "fajr", "details" to "details"),
            mockResult,
        )

        verify { mockResult.success(null) }
    }

    @Test
    fun `getQALogs returns stored logs`() {
        val context = mockk<Context>(relaxed = true)
        every { mockScheduler.getContext() } returns context

        logic.handleMethodCall("getQALogs", null, mockResult)

        verify { mockResult.success(any()) }
    }

    @Test
    fun `clearQALogs clears stored logs`() {
        val context = mockk<Context>(relaxed = true)
        every { mockScheduler.getContext() } returns context

        logic.handleMethodCall("clearQALogs", null, mockResult)

        verify { mockResult.success(null) }
    }

    @Test
    fun `playAdhanNow returns error when startForegroundService throws`() {
        mockkStatic(ContextCompat::class)
        try {
            val context = mockk<Context>(relaxed = true)
            every { mockScheduler.getContext() } returns context
            every { context.packageName } returns "com.tilawa.app"
            every {
                ContextCompat.startForegroundService(any(), any())
            } throws RuntimeException("start failed")

            logic.handleMethodCall(
                "playAdhanNow",
                mapOf("id" to 1, "prayerName" to "fajr"),
                mockResult,
            )

            verify { mockResult.error("PLAY_ADHAN_NOW_FAILED", any(), null) }
        } finally {
            unmockkStatic(ContextCompat::class)
        }
    }

    @Test
    fun `stopAdhan returns error when startService throws`() {
        val context = mockk<Context>(relaxed = true)
        every { mockScheduler.getContext() } returns context
        every { context.packageName } returns "com.tilawa.app"
        every { context.startService(any()) } throws RuntimeException("stop failed")

        logic.handleMethodCall("stopAdhan", null, mockResult)

        verify { mockResult.error("STOP_ADHAN_FAILED", any(), null) }
    }

    @Test
    fun `testAdhanNotification returns false when schedule fails`() {
        val context = mockk<Context>(relaxed = true)
        every { mockScheduler.getContext() } returns context
        every { mockScheduler.schedule(any(), any(), any(), any(), any()) } returns false

        logic.handleMethodCall(
            "testAdhanNotification",
            mapOf("id" to 999, "name" to "qa_test"),
            mockResult,
        )

        verify { mockResult.success(false) }
    }
}
