package com.tilawa.app

import android.content.Intent
import android.os.Build
import com.tilawa.app.prayer.AdhanScheduler
import com.tilawa.app.prayer.PrayerAdhanMethodChannel
import com.tilawa.app.prayer.PrayerNotificationsWatchdogScheduler
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.mockk.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class MainActivityTest {

    private lateinit var activity: MainActivity
    private lateinit var mockEngine: FlutterEngine
    private lateinit var mockMessenger: BinaryMessenger

    @Before
    fun setup() {
        mockkConstructor(MethodChannel::class)
        every { anyConstructed<MethodChannel>().setMethodCallHandler(any()) } just Runs

        activity = Robolectric.buildActivity(MainActivity::class.java).get()

        mockEngine = mockk(relaxed = true)
        mockMessenger = mockk(relaxed = true)
        val mockExecutor = mockk<DartExecutor>(relaxed = true)
        every { mockEngine.dartExecutor } returns mockExecutor
        every { mockExecutor.binaryMessenger } returns mockMessenger

        mockkObject(PrayerAdhanMethodChannel)
        mockkObject(PrayerNotificationsWatchdogScheduler)
        every { PrayerAdhanMethodChannel.register(any(), any()) } just Runs
        every { PrayerAdhanMethodChannel.notifyNotificationTapped(any(), any()) } just Runs
    }

    @After
    fun tearDown() {
        unmockkAll()
    }

    @Test
    fun `getRenderMode always uses texture to avoid surface ANR`() {
        assert(activity.getRenderMode() == RenderMode.texture)
    }

    @Test
    fun `registerAppMethodChannels registers prayer adhan and app channels`() {
        activity.registerAppMethodChannels(mockEngine)

        verify { PrayerAdhanMethodChannel.register(mockMessenger, activity) }
        verify(atLeast = 3) { anyConstructed<MethodChannel>().setMethodCallHandler(any()) }
    }

    @Test
    fun `onNewIntent consumes open prayer status action after routing once`() {
        val intent = Intent(activity, MainActivity::class.java).apply {
            action = MainActivity.ACTION_OPEN_PRAYER_STATUS
            putExtra(AdhanScheduler.EXTRA_PRAYER_NAME, "fajr")
            putExtra(AdhanScheduler.EXTRA_PRAYER_KEY, "fajr")
            putExtra(AdhanScheduler.EXTRA_NOTIFICATION_ID, 2001)
            putExtra(AdhanScheduler.EXTRA_SCHEDULED_MS, 123456789L)
            putExtra("adhan_enabled", true)
            putExtra("is_adhan_playing", true)
        }

        MainActivity::class.java
            .getDeclaredMethod("onNewIntent", Intent::class.java)
            .apply { isAccessible = true }
            .invoke(activity, intent)
        MainActivity::class.java
            .getDeclaredMethod("onNewIntent", Intent::class.java)
            .apply { isAccessible = true }
            .invoke(activity, intent)

        verify(exactly = 1) {
            PrayerAdhanMethodChannel.notifyNotificationTapped(
                "fajr",
                match {
                    it.contains("\"type\":\"prayer\"") &&
                        it.contains("\"prayer\":\"fajr\"") &&
                        it.contains("\"prayer_name\":\"fajr\"") &&
                        it.contains("\"scheduled_time_ms\":123456789") &&
                        it.contains("\"adhan_enabled\":true")
                },
            )
        }
        assert(intent.action == null)
    }
}
