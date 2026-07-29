package com.tilawa.app

import android.app.Application
import android.content.ComponentCallbacks2
import android.content.Context
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.slot
import io.mockk.spyk
import io.mockk.verify
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class SevereMemoryPressureBridgeTest {

    private lateinit var app: Application

    @Before
    fun setUp() {
        SevereMemoryPressureBridge.resetForTest()
        app = RuntimeEnvironment.getApplication()
    }

    @After
    fun tearDown() {
        SevereMemoryPressureBridge.get(app).unregisterForTest(app)
        SevereMemoryPressureBridge.resetForTest()
    }

    @Test
    fun `UI_HIDDEN is not severe so OEM lock noise is ignored`() {
        assertFalse(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN,
            ),
        )
    }

    @Test
    fun `BACKGROUND is not severe so lock unlock does not wipe image cache`() {
        // OPPO fires BACKGROUND on normal background/lock. Clearing Flutter's
        // image cache then forces unlock-frame re-decode (FLUTTER-9).
        assertFalse(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_BACKGROUND,
            ),
        )
    }

    @Test
    fun `RUNNING_CRITICAL MODERATE and COMPLETE are severe`() {
        assertTrue(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
            ),
        )
        assertTrue(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW,
            ),
        )
        assertTrue(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE,
            ),
        )
        assertTrue(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_MODERATE,
            ),
        )
        assertTrue(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_COMPLETE,
            ),
        )
    }

    @Test
    fun `get returns one process-scoped instance across recreate contexts`() {
        // Avoid MainActivity.setup() — native Sentry/relinker fails under unit test.
        val firstCtx = mockk<Context>()
        val secondCtx = mockk<Context>()
        every { firstCtx.applicationContext } returns app
        every { secondCtx.applicationContext } returns app

        val bridgeA = SevereMemoryPressureBridge.get(firstCtx)
        bridgeA.detachChannel(firstCtx)

        val bridgeB = SevereMemoryPressureBridge.get(secondCtx)
        assertSame(bridgeA, bridgeB)
    }

    @Test
    fun `Application registerComponentCallbacks runs exactly once`() {
        val spyApp = spyk(app)
        every { spyApp.applicationContext } returns spyApp

        SevereMemoryPressureBridge.get(spyApp)
        SevereMemoryPressureBridge.get(spyApp)
        SevereMemoryPressureBridge.get(spyApp).ensureRegistered(spyApp)

        verify(exactly = 1) { spyApp.registerComponentCallbacks(any()) }
    }

    @Test
    fun `queued severe flushes exactly once after channel attach`() {
        val bridge = SevereMemoryPressureBridge.get(app)
        val channel = mockk<MethodChannel>(relaxed = true)
        every { channel.invokeMethod(any(), any()) } just Runs

        bridge.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL)
        verify(exactly = 0) { channel.invokeMethod(any(), any()) }

        val owner = Any()
        bridge.attachChannel(owner, channel)

        val argsSlot = slot<Any>()
        verify(exactly = 1) {
            channel.invokeMethod("severe", capture(argsSlot))
        }
        val payload = argsSlot.captured as Map<*, *>
        assertTrue(payload["level"] == ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL)
        assertTrue(payload["reason"] == "trim")

        // Second attach with no pending must not re-invoke.
        bridge.attachChannel(owner, channel)
        verify(exactly = 1) { channel.invokeMethod(any(), any()) }
    }

    @Test
    fun `old Activity detach does not clear newer Activity channel`() {
        val bridge = SevereMemoryPressureBridge.get(app)
        val oldOwner = Any()
        val newOwner = Any()
        val oldChannel = mockk<MethodChannel>(relaxed = true)
        val newChannel = mockk<MethodChannel>(relaxed = true)
        every { oldChannel.invokeMethod(any(), any()) } just Runs
        every { newChannel.invokeMethod(any(), any()) } just Runs

        bridge.attachChannel(oldOwner, oldChannel)
        bridge.attachChannel(newOwner, newChannel)
        bridge.detachChannel(oldOwner)

        bridge.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_COMPLETE)

        val argsSlot = slot<Any>()
        verify(exactly = 1) {
            newChannel.invokeMethod("severe", capture(argsSlot))
        }
        val payload = argsSlot.captured as Map<*, *>
        assertTrue(payload["level"] == ComponentCallbacks2.TRIM_MEMORY_COMPLETE)
        verify(exactly = 0) { oldChannel.invokeMethod(any(), any()) }
        assertNotSame(oldChannel, newChannel)
    }

    @Test
    fun `BACKGROUND trim does not invoke Dart channel`() {
        val bridge = SevereMemoryPressureBridge.get(app)
        val channel = mockk<MethodChannel>(relaxed = true)
        every { channel.invokeMethod(any(), any()) } just Runs
        bridge.attachChannel(Any(), channel)

        bridge.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_BACKGROUND)
        bridge.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN)

        verify(exactly = 0) { channel.invokeMethod(any(), any()) }
    }
}



