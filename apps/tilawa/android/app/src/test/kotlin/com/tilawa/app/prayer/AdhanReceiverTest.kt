package com.tilawa.app.prayer

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config

import io.mockk.*
import org.junit.Before

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class AdhanReceiverTest {
    @Before
    fun setup() {
        mockkConstructor(FirebasePrayerAnalytics::class)
        every { anyConstructed<FirebasePrayerAnalytics>().logEvent(any(), any()) } returns Unit
        every { anyConstructed<FirebasePrayerAnalytics>().logError(any(), any(), any()) } returns Unit
    }

    @Test
    fun `onReceive starts AdhanPlaybackService`() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val receiver = AdhanReceiver()
        val intent = Intent("com.tilawa.app.prayer.ACTION_FIRE_ADHAN").apply {
            putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, 123)
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
        }

        receiver.onReceive(context, intent)

        val shadowContext = Shadows.shadowOf(context as android.app.Application)
        val nextService = shadowContext.nextStartedService
        assertNotNull(nextService)
        assertEquals(AdhanPlaybackService::class.java.name, nextService.component?.className)
        assertEquals(AdhanPlaybackService.ACTION_PLAY, nextService.action)
        assertEquals(123, nextService.getIntExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, -1))
        assertEquals("fajr", nextService.getStringExtra(AdhanScheduler.EXTRA_PRAYER_NAME))
    }

    @Test
    fun `onReceive forwards location and language to playback service`() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val receiver = AdhanReceiver()
        val intent = Intent("com.tilawa.app.prayer.ACTION_FIRE_ADHAN").apply {
            putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, 123)
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_LOCATION_NAME, "Cairo")
            putExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE, "ar")
        }

        receiver.onReceive(context, intent)

        val shadowContext = Shadows.shadowOf(context as android.app.Application)
        val nextService = shadowContext.nextStartedService
        assertNotNull(nextService)
        assertEquals("Cairo", nextService.getStringExtra(AdhanScheduler.EXTRA_LOCATION_NAME))
        assertEquals("ar", nextService.getStringExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE))
    }

    @Test
    fun `onReceive ignores unknown actions`() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val receiver = AdhanReceiver()
        val intent = Intent("UNKNOWN_ACTION")

        receiver.onReceive(context, intent)

        val shadowContext = Shadows.shadowOf(context as android.app.Application)
        assertNull(shadowContext.nextStartedService)
    }
}
