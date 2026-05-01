package com.tilawa.app.prayer

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import io.mockk.*
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

class PrayerNotificationsWatchdogSchedulerTest {

    private lateinit var context: Context
    private lateinit var mockProxy: WorkManagerProxy

    @Before
    fun setup() {
        context = mockk(relaxed = true)
        mockProxy = mockk(relaxed = true)
        PrayerNotificationsWatchdogScheduler.setProxy(mockProxy)
    }

    @Test
    fun `enqueuePeriodic calls proxy`() {
        PrayerNotificationsWatchdogScheduler.enqueuePeriodic(context)
        verify { mockProxy.enqueuePeriodic(context) }
    }
    
    @Test
    fun `enqueueOneTime calls proxy`() {
        PrayerNotificationsWatchdogScheduler.enqueueOneTime(context)
        verify { mockProxy.enqueueOneTime(context) }
    }
}
