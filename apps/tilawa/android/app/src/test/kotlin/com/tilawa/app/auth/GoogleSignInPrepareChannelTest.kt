package com.tilawa.app.auth

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.unmockkObject
import io.mockk.verify
import org.junit.After
import org.junit.Before
import org.junit.Test

class GoogleSignInPrepareChannelTest {

    private lateinit var mockMessenger: BinaryMessenger
    private lateinit var mockActivity: Activity
    private lateinit var mockResult: MethodChannel.Result

    @Before
    fun setUp() {
        mockMessenger = mockk(relaxed = true)
        mockActivity = mockk(relaxed = true)
        mockResult = mockk(relaxed = true)
        mockkObject(GoogleSignInPrepareBridge)
        every {
            GoogleSignInPrepareBridge.prepare(any(), any(), any())
        } answers {
            val callback = thirdArg<(Boolean) -> Unit>()
            callback(true)
        }
        every { GoogleSignInPrepareBridge.clear() } returns Unit
    }

    @After
    fun tearDown() {
        unmockkObject(GoogleSignInPrepareBridge)
        io.mockk.unmockkConstructor(MethodChannel::class)
    }

    @Test
    fun `prepare without google_client_id returns BAD_ARGS`() {
        val handler = captureHandler()

        handler.onMethodCall(MethodCall("prepare", null), mockResult)

        verify {
            mockResult.error("BAD_ARGS", "google_client_id is required", null)
        }
    }

    @Test
    fun `prepare with client id delegates to bridge`() {
        val handler = captureHandler()
        val clientId = "181575856185-test.apps.googleusercontent.com"

        handler.onMethodCall(
            MethodCall("prepare", mapOf("google_client_id" to clientId)),
            mockResult,
        )

        verify {
            GoogleSignInPrepareBridge.prepare(mockActivity, clientId, any())
            mockResult.success(true)
        }
    }

    @Test
    fun `clear delegates to bridge`() {
        val handler = captureHandler()

        handler.onMethodCall(MethodCall("clear", null), mockResult)

        verify {
            GoogleSignInPrepareBridge.clear()
            mockResult.success(null)
        }
    }

    @Test
    fun `unknown method is not implemented`() {
        val handler = captureHandler()

        handler.onMethodCall(MethodCall("unknown", null), mockResult)

        verify { mockResult.notImplemented() }
    }

    private fun captureHandler(): MethodChannel.MethodCallHandler {
        val handlerSlot = slot<MethodChannel.MethodCallHandler>()
        io.mockk.mockkConstructor(MethodChannel::class)
        every {
            anyConstructed<MethodChannel>().setMethodCallHandler(capture(handlerSlot))
        } returns Unit

        GoogleSignInPrepareChannel.register(mockMessenger, mockActivity)

        return handlerSlot.captured
    }
}
