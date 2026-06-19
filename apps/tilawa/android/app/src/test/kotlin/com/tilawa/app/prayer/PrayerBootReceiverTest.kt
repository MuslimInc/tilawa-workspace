package com.tilawa.app.prayer

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import io.mockk.*
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class PrayerBootReceiverTest {

    private lateinit var context: Context
    private val receiver = PrayerBootReceiver()

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        mockkConstructor(FirebasePrayerAnalytics::class)
        every { anyConstructed<FirebasePrayerAnalytics>().logEvent(any(), any()) } returns Unit
        every { anyConstructed<FirebasePrayerAnalytics>().logError(any(), any(), any()) } returns Unit
        
        mockkObject(AdhanScheduler)
        mockkObject(PrayerNotificationsWatchdogScheduler)
    }

    @Test
    fun `onReceive re-arms alarms on BOOT_COMPLETED`() {
        // Setup persisted alarms
        val triggerAt = System.currentTimeMillis() + 3600000
        val entries = listOf(AlarmMetadata(200, "fajr", "fajr", triggerAt, "adhan_fajr"))
        PrayerBootReceiver.persistPendingAlarms(context, entries)
        
        every { AdhanScheduler.schedule(any(), any(), any(), any(), any(), any()) } returns true
        every { PrayerNotificationsWatchdogScheduler.enqueuePeriodic(any()) } just Runs
        every { PrayerNotificationsWatchdogScheduler.enqueueOneTime(any()) } just Runs

        val intent = Intent(Intent.ACTION_BOOT_COMPLETED)
        receiver.onReceive(context, intent)

        // Verify re-arm
        verify { AdhanScheduler.schedule(context, 200, "fajr", "fajr", triggerAt, "adhan_fajr") }
        
        // Verify watchdog scheduling
        verify { PrayerNotificationsWatchdogScheduler.enqueuePeriodic(context) }
        verify { PrayerNotificationsWatchdogScheduler.enqueueOneTime(context) }
        
        // Verify needs_reschedule flag
        assertTrue(DefaultPrayerStorage(context).needsReschedule())
    }

    @Test
    fun `reArmAlarms ignores expired alarms`() {
        val pastTrigger = System.currentTimeMillis() - 1000
        val futureTrigger = System.currentTimeMillis() + 1000
        val entries = listOf(
            AlarmMetadata(201, "expired", "expired", pastTrigger, "adhan"),
            AlarmMetadata(202, "future", "future", futureTrigger, "adhan")
        )
        PrayerBootReceiver.persistPendingAlarms(context, entries)

        every { AdhanScheduler.schedule(any(), any(), any(), any(), any()) } returns true
        every { PrayerNotificationsWatchdogScheduler.enqueuePeriodic(any()) } just Runs
        every { PrayerNotificationsWatchdogScheduler.enqueueOneTime(any()) } just Runs

        val intent = Intent(Intent.ACTION_TIMEZONE_CHANGED)
        receiver.onReceive(context, intent)

        verify(exactly = 0) { AdhanScheduler.schedule(any(), 201, any(), any(), any(), any()) }
        verify(exactly = 1) { AdhanScheduler.schedule(any(), 202, any(), any(), any(), any()) }
    }

    @Test
    fun `handles corrupted JSON safely`() {
        context.getSharedPreferences("prayer_adhan_alarms", Context.MODE_PRIVATE)
            .edit()
            .putString("pending_alarms_json", "invalid-json")
            .commit()

        every { PrayerNotificationsWatchdogScheduler.enqueuePeriodic(any()) } just Runs
        every { PrayerNotificationsWatchdogScheduler.enqueueOneTime(any()) } just Runs

        // Should not crash
        receiver.onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))
        
        verify { PrayerNotificationsWatchdogScheduler.enqueuePeriodic(context) }
    }

    @Test
    fun `persistPendingAlarms stores location and language in JSON`() {
        val triggerAt = System.currentTimeMillis() + 3600000
        val entries = listOf(
            AlarmMetadata(
                id = 300,
                name = "fajr",
                key = "fajr",
                triggerMs = triggerAt,
                sound = "adhan_fajr",
                locationName = "Cairo",
                languageCode = "ar",
            ),
        )

        PrayerBootReceiver.persistPendingAlarms(context, entries)

        val raw = DefaultPrayerStorage(context).getPendingAlarmsJson()
        assertNotNull(raw)
        assertTrue(raw!!.contains("\"location\":\"Cairo\""))
        assertTrue(raw.contains("\"language\":\"ar\""))
    }

    @Test
    fun `onReceive ignores unknown actions`() {
        every { PrayerNotificationsWatchdogScheduler.enqueuePeriodic(any()) } just Runs
        every { PrayerNotificationsWatchdogScheduler.enqueueOneTime(any()) } just Runs

        receiver.onReceive(context, Intent("com.example.UNKNOWN"))

        verify(exactly = 0) { PrayerNotificationsWatchdogScheduler.enqueuePeriodic(any()) }
    }

    @Test
    fun `clearPendingAlarms removes persisted JSON`() {
        val triggerAt = System.currentTimeMillis() + 3600000
        PrayerBootReceiver.persistPendingAlarms(
            context,
            listOf(AlarmMetadata(400, "fajr", "fajr", triggerAt, "adhan")),
        )

        PrayerBootReceiver.clearPendingAlarms(context)

        assertNull(DefaultPrayerStorage(context).getPendingAlarmsJson())
    }
}
