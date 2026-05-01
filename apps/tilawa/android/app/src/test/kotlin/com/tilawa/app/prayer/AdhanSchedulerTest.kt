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
        every { mockAM.scheduleExact(any(), any(), any()) } returns true
        
        val result = AdhanScheduler.schedule(context, 1, "fajr", 1000L)
        
        assertTrue(result)
        verify { mockAM.scheduleExact(1, "fajr", 1000L) }
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
}
