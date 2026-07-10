package com.tilawa.app.prayer

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.R])
class DefaultPrayerAlarmManagerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `scheduleExact stores location and language extras on alarm intent`() {
        val manager = DefaultPrayerAlarmManager(context)
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val shadowAlarmManager = Shadows.shadowOf(alarmManager)

        val ok = manager.scheduleExact(
            id = 42,
            name = "fajr",
            key = "fajr",
            triggerMs = 1_700_000_000_000L,
            sound = "adhan_fajr",
            locationName = "Cairo",
            languageCode = "ar",
        )

        assertTrue(ok)
        val scheduled = shadowAlarmManager.scheduledAlarms.single()
        val pendingIntent = scheduled.operation
        assertNotNull(pendingIntent)
        val broadcastIntent = Shadows.shadowOf(pendingIntent!!).savedIntent
        assertEquals("com.tilawa.app.prayer.ACTION_FIRE_ADHAN", broadcastIntent.action)
        assertEquals("Cairo", broadcastIntent.getStringExtra(AdhanScheduler.EXTRA_LOCATION_NAME))
        assertEquals("ar", broadcastIntent.getStringExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE))
        assertEquals("fajr", broadcastIntent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME))
        assertEquals("adhan_fajr", broadcastIntent.getStringExtra(AdhanScheduler.EXTRA_SOUND))
    }

    @Test
    fun `scheduleInexact stores location and language extras on alarm intent`() {
        val manager = DefaultPrayerAlarmManager(context)
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val shadowAlarmManager = Shadows.shadowOf(alarmManager)

        val ok = manager.scheduleInexact(
            id = 43,
            name = "isha",
            key = "isha",
            triggerMs = 1_700_000_100_000L,
            sound = "adhan",
            locationName = "Cairo",
            languageCode = "ar",
        )

        assertTrue(ok)
        val scheduled = shadowAlarmManager.scheduledAlarms.single()
        val pendingIntent = scheduled.operation
        assertNotNull(pendingIntent)
        val broadcastIntent = Shadows.shadowOf(pendingIntent!!).savedIntent
        assertEquals("com.tilawa.app.prayer.ACTION_FIRE_ADHAN", broadcastIntent.action)
        assertEquals("Cairo", broadcastIntent.getStringExtra(AdhanScheduler.EXTRA_LOCATION_NAME))
        assertEquals("ar", broadcastIntent.getStringExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE))
        assertEquals("isha", broadcastIntent.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME))
        assertEquals("adhan", broadcastIntent.getStringExtra(AdhanScheduler.EXTRA_SOUND))
    }

    @Test
    fun `canScheduleExact returns true on Android 11`() {
        val manager = DefaultPrayerAlarmManager(context)
        assertTrue(manager.canScheduleExact())
    }

    @Test
    fun `cancel clears pending alarm for id`() {
        val manager = DefaultPrayerAlarmManager(context)
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val shadowAlarmManager = Shadows.shadowOf(alarmManager)

        manager.scheduleExact(
            id = 99,
            name = "maghrib",
            key = "maghrib",
            triggerMs = 1_700_000_000_000L,
            sound = "adhan",
            locationName = "Riyadh",
            languageCode = "ar",
        )
        assertEquals(1, shadowAlarmManager.scheduledAlarms.size)

        manager.cancel(99)

        assertTrue(shadowAlarmManager.scheduledAlarms.isEmpty())
    }
}
