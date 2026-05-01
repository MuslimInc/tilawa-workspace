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
        every { mockScheduler.schedule(any(), any(), any()) } returns true
        
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
    fun `reArmAlarms schedules future alarms from JSON`() {
        val now = 1000L
        val json = """
            [
                {"id": 1, "name": "fajr", "trigger": 500},
                {"id": 2, "name": "dhuhr", "trigger": 1500},
                {"id": 3, "name": "asr", "trigger": 2500}
            ]
        """.trimIndent()
        
        every { mockStorage.getPendingAlarmsJson() } returns json
        
        logic.reArmAlarms(now)
        
        // id 1 is in the past (500 <= 1000), should NOT be scheduled
        verify(exactly = 0) { mockScheduler.schedule(1, any(), any()) }
        
        // id 2 and 3 are in the future
        verify { mockScheduler.schedule(any(), any(), any()) }
        verify { mockScheduler.schedule(any(), any(), any()) }
    }

    @Test
    fun `reArmAlarms handles corrupted JSON gracefully`() {
        every { mockStorage.getPendingAlarmsJson() } returns "{ corrupted"
        
        // Should not throw exception
        logic.reArmAlarms(1000L)
        
        verify(exactly = 0) { mockScheduler.schedule(any(), any(), any()) }
    }
    
    @Test
    fun `reArmAlarms handles empty JSON`() {
        every { mockStorage.getPendingAlarmsJson() } returns "[]"
        
        logic.reArmAlarms(1000L)
        
        verify(exactly = 0) { mockScheduler.schedule(any(), any(), any()) }
    }
}
