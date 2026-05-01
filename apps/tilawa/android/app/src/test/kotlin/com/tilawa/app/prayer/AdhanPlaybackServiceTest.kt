package com.tilawa.app.prayer

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import io.mockk.*
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowService

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class AdhanPlaybackServiceTest {

    private lateinit var context: Context
    private lateinit var shadowService: ShadowService
    private lateinit var service: AdhanPlaybackService

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        // Mock Firebase Analytics initialization
        mockkConstructor(FirebasePrayerAnalytics::class)
        every { anyConstructed<FirebasePrayerAnalytics>().logEvent(any(), any()) } returns Unit
        every { anyConstructed<FirebasePrayerAnalytics>().logError(any(), any(), any()) } returns Unit

        // Mock MediaPlayer constructor to avoid native issues in JVM
        mockkConstructor(MediaPlayer::class)
        every { anyConstructed<MediaPlayer>().setDataSource(any<Context>(), any()) } returns Unit
        every { anyConstructed<MediaPlayer>().setAudioAttributes(any()) } returns Unit
        every { anyConstructed<MediaPlayer>().prepare() } returns Unit
        every { anyConstructed<MediaPlayer>().start() } returns Unit
        every { anyConstructed<MediaPlayer>().stop() } returns Unit
        every { anyConstructed<MediaPlayer>().release() } returns Unit
        every { anyConstructed<MediaPlayer>().setOnCompletionListener(any()) } returns Unit
        every { anyConstructed<MediaPlayer>().setOnErrorListener(any()) } returns Unit
    }

    @Test
    fun `onStartCommand with ACTION_PLAY starts foreground and plays`() {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis() - 5000)
            putExtra("receiver_time", System.currentTimeMillis() - 1000)
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan_fajr")
        }
        
        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)

        service.onStartCommand(intent, 0, 1)

        // Verify foreground
        val notification = shadowService.lastForegroundNotification
        assertNotNull(notification)
        
        // Verify metrics were logged
        verify { anyConstructed<FirebasePrayerAnalytics>().logEvent("prayer_trigger_delta", any()) }
        verify { anyConstructed<FirebasePrayerAnalytics>().logEvent("prayer_service_start_latency", any()) }

        // Verify MediaPlayer was started
        verify { anyConstructed<MediaPlayer>().start() }
    }

    @Test
    fun `onStartCommand with ACTION_STOP stops service`() {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_STOP
        }
        
        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)

        service.onStartCommand(intent, 0, 1)

        assertTrue(shadowService.isStoppedBySelf)
    }

    @Test
    fun `onDestroy releases resources`() {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
        }
        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        service.onStartCommand(intent, 0, 1)

        controller.destroy()

        verify { anyConstructed<MediaPlayer>().release() }
    }

    @Test
    fun `onDestroy logs abnormal termination if not completed`() {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
        }
        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        
        // Start playback but don't finish it
        service.onStartCommand(intent, 0, 1)
        
        controller.destroy()
        
        // Verify abnormal termination log
        verify { anyConstructed<FirebasePrayerAnalytics>().logEvent("prayer_service_abnormal_termination", any()) }
    }
}
