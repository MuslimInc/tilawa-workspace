package com.tilawa.app.prayer

import io.mockk.*
import org.junit.Test
import org.junit.Assert.*

import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class BootLogicTest {
    private val mockStorage = mockk<PrayerStorage>(relaxed = true)
    private val mockScheduler = mockk<AdhanSchedulerProxy>(relaxed = true)
    private val mockWatchdog = mockk<WatchdogProxy>(relaxed = true)
    private val mockAnalytics = mockk<PrayerAnalytics>(relaxed = true)
    private val logic = BootLogic(mockStorage, mockScheduler, mockWatchdog, mockAnalytics)

    @Test
    fun `reArmAlarms logs successes`() {
        val json = """[{"id": 2, "name": "dhuhr", "trigger": 1500}]"""
        every { mockStorage.getPendingAlarmsJson() } returns json
        every { mockScheduler.schedule(any(), any(), any(), any(), any()) } returns true
        
        logic.reArmAlarms(1000L)
        
        verify { mockAnalytics.logEvent(PrayerEvents.SCHEDULE_SUCCESS, any()) }
    }

    @Test
    fun `reArmAlarms sets needs reschedule and enqueues watchdog`() {
        logic.reArmAlarms(1000L)
        
        verify { mockStorage.setNeedsReschedule(true) }
        verify { mockWatchdog.enqueuePeriodic() }
        verify { mockWatchdog.enqueueOneTime() }
    }

    @Test
    fun `reArmPendingAlarmsForWatchdog re-arms without enqueuing watchdog`() {
        val json = """[{"id": 2, "name": "dhuhr", "trigger": 1500}]"""
        every { mockStorage.getPendingAlarmsJson() } returns json
        every {
            mockScheduler.schedule(any(), any(), any(), any(), any(), any(), any())
        } returns true

        val scheduled = logic.reArmPendingAlarmsForWatchdog(1000L)

        assertEquals(1, scheduled)
        verify { mockStorage.setNeedsReschedule(true) }
        verify(exactly = 0) { mockWatchdog.enqueuePeriodic() }
        verify(exactly = 0) { mockWatchdog.enqueueOneTime() }
        verify { mockScheduler.schedule(2, "dhuhr", "dhuhr", 1500L, "adhan") }
        verify {
            mockAnalytics.logEvent(
                PrayerEvents.SCHEDULE_SUCCESS,
                match { it["context"] == "watchdog_rearm" },
            )
        }
    }

    @Test
    fun `reArmAlarms schedules future alarms from JSON`() {
        val now = 1000L
        val json = """
            [
                {"id": 1, "name": "fajr", "trigger": 500},
                {"id": 2, "name": "dhuhr", "trigger": 1500},
                {"id": 3, "name": "asr", "trigger": 2500, "sound": "adhan_fajr"}
            ]
        """.trimIndent()
        
        every { mockStorage.getPendingAlarmsJson() } returns json
        
        logic.reArmAlarms(now)
        
        // id 1 is in the past (500 <= 1000), should NOT be scheduled
        verify(exactly = 0) { mockScheduler.schedule(1, any(), any(), any(), any()) }
        
        // id 2 and 3 are in the future
        verify { mockScheduler.schedule(2, "dhuhr", "dhuhr", 1500L, "adhan") }
        verify { mockScheduler.schedule(3, "asr", "asr", 2500L, "adhan_fajr") }
    }

    @Test
    fun `reArmAlarms handles corrupted JSON gracefully`() {
        every { mockStorage.getPendingAlarmsJson() } returns "{ corrupted"
        
        // Should not throw exception
        logic.reArmAlarms(1000L)
        
        verify(exactly = 0) { mockScheduler.schedule(any(), any(), any(), any(), any()) }
    }
    
    @Test
    fun `reArmAlarms handles empty JSON`() {
        every { mockStorage.getPendingAlarmsJson() } returns "[]"
        
        logic.reArmAlarms(1000L)
        
        verify(exactly = 0) { mockScheduler.schedule(any(), any(), any(), any(), any()) }
    }

    @Test
    fun `reArmAlarms handles JSON without sound field (legacy)`() {
        val json = """[{"id": 2, "name": "fajr", "trigger": 1500}]"""
        every { mockStorage.getPendingAlarmsJson() } returns json
        
        logic.reArmAlarms(1000L)
        
        // Should default to "adhan"
        verify { mockScheduler.schedule(2, "fajr", "fajr", 1500L, "adhan") }
    }

    @Test
    fun `reArmAlarms forwards location and language from JSON`() {
        val json = """
            [
                {
                    "id": 4,
                    "name": "fajr",
                    "key": "fajr",
                    "trigger": 2500,
                    "sound": "adhan_fajr",
                    "location": "Cairo",
                    "language": "ar"
                }
            ]
        """.trimIndent()
        every { mockStorage.getPendingAlarmsJson() } returns json

        logic.reArmAlarms(1000L)

        verify {
            mockScheduler.schedule(
                4,
                "fajr",
                "fajr",
                2500L,
                "adhan_fajr",
                "Cairo",
                "ar",
            )
        }
    }

    @Test
    fun `reArmAlarms logs schedule failure when scheduler returns false`() {
        val json = """[{"id": 2, "name": "dhuhr", "trigger": 1500}]"""
        every { mockStorage.getPendingAlarmsJson() } returns json
        every { mockScheduler.schedule(any(), any(), any(), any(), any(), any(), any()) } returns false
        every { mockScheduler.canScheduleExact() } returns false
        every { mockScheduler.areNotificationsEnabled() } returns true

        logic.reArmAlarms(1000L)

        verify { mockAnalytics.logEvent(PrayerEvents.SCHEDULE_FAILED, any()) }
    }

    @Test
    fun `reArmAlarms logs analytics error when schedule throws`() {
        val json = """[{"id": 2, "name": "dhuhr", "trigger": 1500}]"""
        every { mockStorage.getPendingAlarmsJson() } returns json
        every {
            mockScheduler.schedule(any(), any(), any(), any(), any(), any(), any())
        } throws RuntimeException("schedule boom")
        every { mockScheduler.canScheduleExact() } returns true
        every { mockScheduler.areNotificationsEnabled() } returns true

        logic.reArmAlarms(1000L)

        verify {
            mockAnalytics.logError(
                "Failed to schedule alarm during boot re-arm",
                any(),
                any(),
            )
        }
    }

    @Test
    fun `reArmAlarms logs analytics error when JSON parse fails`() {
        every { mockStorage.getPendingAlarmsJson() } returns "{ bad json"
        every { mockScheduler.canScheduleExact() } returns true
        every { mockScheduler.areNotificationsEnabled() } returns true

        logic.reArmAlarms(1000L)

        verify {
            mockAnalytics.logError(
                "Failed to parse pending alarms JSON",
                any(),
                any(),
            )
        }
    }

    @Test
    fun `reArmAlarms recalculates wall-clock triggers instead of stale millis`() {
        val zoneId = java.util.TimeZone.getDefault()
        val calendar = java.util.Calendar.getInstance(zoneId).apply {
            set(java.util.Calendar.MILLISECOND, 0)
            set(2026, java.util.Calendar.JUNE, 1, 5, 15, 0)
        }
        val expected = calendar.timeInMillis
        val stale = expected + 3_600_000L // pretend persisted wrong absolute time
        val json = """
            [{
              "id": 9,
              "name": "fajr",
              "key": "fajr",
              "trigger": $stale,
              "sound": "adhan_fajr",
              "year": 2026,
              "month": 6,
              "day": 1,
              "hour": 5,
              "minute": 15
            }]
        """.trimIndent()
        every { mockStorage.getPendingAlarmsJson() } returns json
        every {
            mockScheduler.schedule(any(), any(), any(), any(), any(), any(), any())
        } returns true

        val scheduled = logic.reArmPendingAlarmsForWatchdog(expected - 1_000L)

        assertEquals(1, scheduled)
        verify { mockScheduler.schedule(9, "fajr", "fajr", expected, "adhan_fajr") }
        verify { mockStorage.setPendingAlarmsJson(match { it.contains("\"year\":2026") }) }
    }


}
