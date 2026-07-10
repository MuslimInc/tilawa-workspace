package com.tilawa.app.prayer

import androidx.test.core.app.ApplicationProvider
import io.mockk.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class AdhanSchedulerTest {

    @Test
    fun `schedule delegates to alarm manager and storage`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val mockAM = mockk<PrayerAlarmManager>(relaxed = true)
        val mockST = mockk<PrayerStorage>(relaxed = true)
        
        AdhanScheduler.setDependencies(mockST, mockAM)
        
        every { mockAM.canScheduleExact() } returns true
        every { mockAM.scheduleExact(any(), any(), any(), any(), any()) } returns true
        
        val result = AdhanScheduler.schedule(context, 1, "fajr", "fajr", 1000L, "adhan")
        
        assertTrue(result)
        verify { mockAM.scheduleExact(1, "fajr", "fajr", 1000L, "adhan") }
        verify { mockST.addActiveId(1) }
    }

    @Test
    fun `cancel delegates to alarm manager and storage`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val mockAM = mockk<PrayerAlarmManager>(relaxed = true)
        val mockST = mockk<PrayerStorage>(relaxed = true)
        
        AdhanScheduler.setDependencies(mockST, mockAM)
        
        AdhanScheduler.cancel(context, 1)
        
        verify { mockAM.cancel(1) }
        verify { mockST.removeActiveId(1) }
    }

    @Test
    fun `schedule with location and language delegates to alarm manager`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val mockAM = mockk<PrayerAlarmManager>(relaxed = true)
        val mockST = mockk<PrayerStorage>(relaxed = true)

        AdhanScheduler.setDependencies(mockST, mockAM)

        every { mockAM.canScheduleExact() } returns true
        every {
            mockAM.scheduleExact(1, "fajr", "fajr", 1000L, "adhan_fajr", "Cairo", "ar")
        } returns true

        val result = AdhanScheduler.schedule(
            context,
            1,
            "fajr",
            "fajr",
            1000L,
            "adhan_fajr",
            "Cairo",
            "ar",
        )

        assertTrue(result)
        verify {
            mockAM.scheduleExact(1, "fajr", "fajr", 1000L, "adhan_fajr", "Cairo", "ar")
        }
    }

    @Test
    fun `schedule uses native inexact fallback when exact alarms unavailable`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val mockAM = mockk<PrayerAlarmManager>(relaxed = true)
        val mockST = mockk<PrayerStorage>(relaxed = true)

        AdhanScheduler.setDependencies(mockST, mockAM)
        every { mockAM.canScheduleExact() } returns false
        every {
            mockAM.scheduleInexact(1, "fajr", "fajr", 1000L, "adhan_fajr")
        } returns true

        val result = AdhanScheduler.schedule(context, 1, "fajr", "fajr", 1000L)

        assertTrue(result)
        verify { mockAM.scheduleInexact(1, "fajr", "fajr", 1000L, "adhan_fajr") }
        verify(exactly = 0) { mockAM.scheduleExact(any(), any(), any(), any(), any()) }
        verify { mockST.addActiveId(1) }
    }

    @Test
    fun `schedule returns false when native fallback also fails`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val mockAM = mockk<PrayerAlarmManager>(relaxed = true)
        val mockST = mockk<PrayerStorage>(relaxed = true)

        AdhanScheduler.setDependencies(mockST, mockAM)
        every { mockAM.canScheduleExact() } returns false
        every {
            mockAM.scheduleInexact(1, "fajr", "fajr", 1000L, "adhan_fajr")
        } returns false

        val result = AdhanScheduler.schedule(context, 1, "fajr", "fajr", 1000L)

        assertFalse(result)
        verify { mockAM.scheduleInexact(1, "fajr", "fajr", 1000L, "adhan_fajr") }
        verify(exactly = 0) { mockST.addActiveId(any()) }
    }

    @Test
    fun `cancelAll clears active ids and pending json`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val mockAM = mockk<PrayerAlarmManager>(relaxed = true)
        val mockST = mockk<PrayerStorage>(relaxed = true)

        AdhanScheduler.setDependencies(mockST, mockAM)
        every { mockST.getActiveIds() } returns setOf(1, 2)

        AdhanScheduler.cancelAll(context)

        verify { mockAM.cancelAll(setOf(1, 2)) }
        verify { mockST.clearActiveIds() }
        verify { mockST.setPendingAlarmsJson(null) }
    }

    @Test
    fun `basic schedule chooses fajr sound for fajr key`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val mockAM = mockk<PrayerAlarmManager>(relaxed = true)
        val mockST = mockk<PrayerStorage>(relaxed = true)

        AdhanScheduler.setDependencies(mockST, mockAM)
        every { mockAM.canScheduleExact() } returns true
        every { mockAM.scheduleExact(3, "fajr", "fajr", 5000L, "adhan_fajr") } returns true

        val result = AdhanScheduler.schedule(context, 3, "fajr", "fajr", 5000L)

        assertTrue(result)
        verify { mockAM.scheduleExact(3, "fajr", "fajr", 5000L, "adhan_fajr") }
    }

    @Test
    fun `schedule with location and language uses inexact fallback`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val mockAM = mockk<PrayerAlarmManager>(relaxed = true)
        val mockST = mockk<PrayerStorage>(relaxed = true)

        AdhanScheduler.setDependencies(mockST, mockAM)
        every { mockAM.canScheduleExact() } returns false
        every {
            mockAM.scheduleInexact(1, "fajr", "fajr", 1000L, "adhan_fajr", "Cairo", "ar")
        } returns true

        val result = AdhanScheduler.schedule(
            context,
            1,
            "fajr",
            "fajr",
            1000L,
            "adhan_fajr",
            "Cairo",
            "ar",
        )

        assertTrue(result)
        verify {
            mockAM.scheduleInexact(1, "fajr", "fajr", 1000L, "adhan_fajr", "Cairo", "ar")
        }
        verify { mockST.addActiveId(1) }
    }
}
