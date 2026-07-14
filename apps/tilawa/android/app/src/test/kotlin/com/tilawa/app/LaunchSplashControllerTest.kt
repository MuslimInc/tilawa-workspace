package com.tilawa.app

import android.os.Build
import android.os.Handler
import android.os.Looper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.atomic.AtomicInteger

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class LaunchSplashControllerTest {

    private lateinit var mainHandler: Handler
    private lateinit var shadowLooper: ShadowLooper
    private val logs = mutableListOf<String>()
    private val dismissCount = AtomicInteger(0)

    @Before
    fun setup() {
        logs.clear()
        dismissCount.set(0)
        mainHandler = Handler(Looper.getMainLooper())
        shadowLooper = Shadows.shadowOf(Looper.getMainLooper())
    }

    private fun newController(failsafeMs: Long = 1_000L): LaunchSplashController {
        return LaunchSplashController(
            mainHandler = mainHandler,
            failsafeMs = failsafeMs,
            log = { logs.add(it) },
            onDismissed = { dismissCount.incrementAndGet() },
        )
    }

    @Test
    fun `resetForCreate keeps splash on screen and schedules failsafe`() {
        val controller = newController(failsafeMs = 500L)
        controller.resetForCreate()

        assertTrue(controller.keepOnScreen)
        assertTrue(logs.any { it.contains("failsafe scheduled") })

        shadowLooper.idleFor(java.time.Duration.ofMillis(500L))
        assertFalse(controller.keepOnScreen)
        assertEquals(1, dismissCount.get())
        assertTrue(logs.any { it.contains("FAILSAFE") })
    }

    @Test
    fun `dismissFromFlutterReady cancels failsafe and dismisses once`() {
        val controller = newController(failsafeMs = 2_000L)
        controller.resetForCreate()

        controller.dismissFromFlutterReady()
        controller.dismissFromFlutterReady()

        assertFalse(controller.keepOnScreen)
        assertEquals(1, dismissCount.get())

        shadowLooper.idleFor(java.time.Duration.ofMillis(2_500L))
        assertEquals(1, dismissCount.get())
        assertTrue(logs.any { it.contains("flutter_ready") })
        assertTrue(logs.none { it.contains("FAILSAFE") })
    }

    @Test
    fun `onDestroy cancels pending failsafe`() {
        val controller = newController(failsafeMs = 1_000L)
        controller.resetForCreate()
        controller.onDestroy()

        shadowLooper.idleFor(java.time.Duration.ofMillis(1_500L))
        assertTrue(controller.keepOnScreen)
        assertEquals(0, dismissCount.get())
    }
}
