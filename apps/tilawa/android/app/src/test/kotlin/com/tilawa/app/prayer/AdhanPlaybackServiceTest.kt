package com.tilawa.app.prayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.tilawa.app.R
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
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class AdhanPlaybackServiceTest {

    companion object {
        /** Flutter audible adhan channel — must never host native FGS playback. */
        private const val AUDIBLE_ADHAN_CHANNEL_ID = "com.tilawa.app.prayer_adhan_v5"

        /** Mirrors native [AdhanPlaybackService] silent foreground channel id. */
        private const val NATIVE_FG_CHANNEL_ID = "com.tilawa.app.prayer_adhan_silent_v5"
    }

    private lateinit var context: Context
    private lateinit var shadowService: ShadowService
    private lateinit var service: AdhanPlaybackService

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        // Companion-held gate survives across tests in the same sandbox.
        AdhanPlaybackService.resetStartGateForTest()
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
        verify { anyConstructed<FirebasePrayerAnalytics>().logEvent(PrayerEvents.SERVICE_STARTED, any()) }

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
        verify { anyConstructed<FirebasePrayerAnalytics>().logEvent(PrayerEvents.ABNORMAL_TERMINATION, any()) }
    }

    @Test
    fun `activePayload captured on ACTION_PLAY and cleared on destroy`() {
        // Ensure no leftover from another test
        AdhanPlaybackService.setActivePayloadForTest(null)

        val scheduledMs = System.currentTimeMillis() - 5000
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "dhuhr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "dhuhr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, scheduledMs)
            putExtra("receiver_time", System.currentTimeMillis() - 1000)
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }

        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        service.onStartCommand(intent, 0, 1)

        val payload = AdhanPlaybackService.activePayload
        assertNotNull(payload)
        assertEquals("dhuhr", payload!!.prayerName)
        assertEquals("dhuhr", payload.prayerKey)
        assertEquals("adhan", payload.sound)
        assertEquals(scheduledMs, payload.scheduledMs)

        controller.destroy()

        assertNull(AdhanPlaybackService.activePayload)
    }

    @Test
    fun `foreground notification body is adhan_is_playing while title is prayer name`() {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }

        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(intent, 0, 1)

        val notification = shadowService.lastForegroundNotification
        assertNotNull(notification)
        assertEquals("Fajr", notification.extras.getCharSequence(Notification.EXTRA_TITLE))
        assertEquals(
            context.getString(R.string.adhan_notification_body),
            notification.extras.getCharSequence(Notification.EXTRA_TEXT),
        )
    }

    @Test
    fun `foreground notification includes location in title and body`() {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
            putExtra(AdhanScheduler.EXTRA_LOCATION_NAME, "Cairo")
        }

        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(intent, 0, 1)

        val notification = shadowService.lastForegroundNotification
        assertNotNull(notification)
        assertEquals(
            context.getString(R.string.adhan_notification_title, "Fajr", "Cairo"),
            notification.extras.getCharSequence(Notification.EXTRA_TITLE),
        )
        assertEquals(
            context.getString(R.string.adhan_notification_body_with_location, "Cairo"),
            notification.extras.getCharSequence(Notification.EXTRA_TEXT),
        )
    }

    @Test
    fun `foreground notification uses Flutter language code instead of device locale`() {
        val arabicResources = NotificationLocaleHelper.localizedResources(context, "ar")
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
            putExtra(AdhanScheduler.EXTRA_LANGUAGE_CODE, "ar")
        }

        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(intent, 0, 1)

        val notification = shadowService.lastForegroundNotification
        assertNotNull(notification)
        val fajrResId = arabicResources.getIdentifier("prayer_fajr", "string", context.packageName)
        val bodyResId = arabicResources.getIdentifier("adhan_notification_body", "string", context.packageName)
        val stopResId = arabicResources.getIdentifier("stop_adhan", "string", context.packageName)
        assertEquals(
            arabicResources.getString(fajrResId),
            notification.extras.getCharSequence(Notification.EXTRA_TITLE),
        )
        assertEquals(
            arabicResources.getString(bodyResId),
            notification.extras.getCharSequence(Notification.EXTRA_TEXT),
        )
        assertEquals(
            arabicResources.getString(stopResId),
            notification.actions?.first()?.title,
        )
    }

    @Test
    fun `foreground notification falls back to persisted location when intent extra is missing`() {
        DefaultPrayerStorage(context).setLastNotificationLocationName("Cairo")

        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }

        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(intent, 0, 1)

        val notification = shadowService.lastForegroundNotification
        assertNotNull(notification)
        assertEquals(
            context.getString(R.string.adhan_notification_title, "Fajr", "Cairo"),
            notification.extras.getCharSequence(Notification.EXTRA_TITLE),
        )
        assertEquals(
            context.getString(R.string.adhan_notification_body_with_location, "Cairo"),
            notification.extras.getCharSequence(Notification.EXTRA_TEXT),
        )
    }

    @Test
    fun `second ACTION_PLAY while already playing does not start MediaPlayer again`() {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }

        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        service.onStartCommand(intent, 0, 1)
        service.onStartCommand(intent, 0, 2)

        verify(exactly = 1) { anyConstructed<MediaPlayer>().start() }
        verify {
            anyConstructed<FirebasePrayerAnalytics>().logEvent(
                PrayerEvents.DUPLICATE_GUARD,
                any(),
            )
        }
    }

    @Test
    fun `re-delivered alarm for the same event does not start a second playback session`() {
        val scheduledMs = System.currentTimeMillis()
        fun playIntent() = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, scheduledMs)
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }

        // First delivery plays, then the service is torn down (user stop /
        // completion). A duplicate delivery of the SAME event must not replay.
        val first = Robolectric.buildService(AdhanPlaybackService::class.java, playIntent())
        first.get().onStartCommand(playIntent(), 0, 1)
        first.destroy()

        val second = Robolectric.buildService(AdhanPlaybackService::class.java, playIntent())
        service = second.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(playIntent(), 0, 1)

        verify(exactly = 1) { anyConstructed<MediaPlayer>().start() }
    }

    @Test
    fun `native playback uses silent channel when flutter already registered audible adhan channel`() {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val audibleSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        nm.createNotificationChannel(
            NotificationChannel(
                AUDIBLE_ADHAN_CHANNEL_ID,
                "Prayer Times (Adhan)",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                setSound(
                    audibleSound,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
            },
        )

        assertNotNull(
            "Precondition: Flutter-side init should leave the audible channel with sound",
            nm.getNotificationChannel(AUDIBLE_ADHAN_CHANNEL_ID)?.sound,
        )

        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }
        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(intent, 0, 1)

        val nativeChannel = nm.getNotificationChannel(NATIVE_FG_CHANNEL_ID)
        assertNotNull(
            "Native Adhan is playing notification must post on the silent channel",
            nativeChannel,
        )
        assertNull(
            "Native foreground channel must stay silent so only MediaPlayer plays adhan",
            nativeChannel?.sound,
        )
        assertEquals(
            NATIVE_FG_CHANNEL_ID,
            shadowService.lastForegroundNotification?.channelId,
        )
    }

    @Test
    fun `native playback silent channel is created without sound or vibration`() {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }
        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(intent, 0, 1)

        val nativeChannel = nm.getNotificationChannel(NATIVE_FG_CHANNEL_ID)
        assertNotNull(nativeChannel)
        assertFalse(
            "FGS notification must not vibrate over the start of adhan playback",
            nativeChannel!!.shouldVibrate(),
        )
        assertNull(
            "FGS channel must stay silent so only MediaPlayer plays adhan",
            nativeChannel.sound,
        )
    }

    @Test
    fun `default adhan raw resource is packaged and protected from shrinking`() {
        assertEquals(
            R.raw.adhan,
            context.resources.getIdentifier("adhan", "raw", context.packageName),
        )

        val keepFile = listOf(
            File("src/main/res/raw/keep.xml"),
            File("app/src/main/res/raw/keep.xml"),
        ).firstOrNull { it.isFile }

        assertNotNull("raw keep.xml must exist", keepFile)
        assertTrue(
            "raw keep.xml must keep the dynamically-loaded adhan sound",
            keepFile!!.readText().contains("@raw/adhan"),
        )
    }

    @Test
    fun `startPlayback stops service when MediaPlayer prepare fails`() {
        every { anyConstructed<MediaPlayer>().prepare() } throws RuntimeException("prepare failed")

        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }

        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(intent, 0, 1)

        verify(exactly = 0) { anyConstructed<MediaPlayer>().start() }
        verify { anyConstructed<FirebasePrayerAnalytics>().logEvent(PrayerEvents.PLAYBACK_FAILED, any()) }
        assertTrue(shadowService.isStoppedBySelf)
    }

    @Test
    @Config(sdk = [Build.VERSION_CODES.P])
    fun `startPlayback uses legacy startForeground on pre-Q devices`() {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, System.currentTimeMillis())
            putExtra(AdhanScheduler.EXTRA_SOUND, "adhan")
        }

        val controller = Robolectric.buildService(AdhanPlaybackService::class.java, intent)
        service = controller.get()
        shadowService = Shadows.shadowOf(service)
        service.onStartCommand(intent, 0, 1)

        assertNotNull(shadowService.lastForegroundNotification)
        verify { anyConstructed<MediaPlayer>().start() }
    }
}
