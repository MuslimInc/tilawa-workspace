package com.tilawa.app.prayer

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.*
import org.junit.Before
import org.junit.Test

class PrayerAdhanMethodChannelTest {

    private lateinit var mockMessenger: BinaryMessenger
    private lateinit var mockContext: Context
    private lateinit var mockLogic: MethodChannelLogic
    private lateinit var mockResult: MethodChannel.Result

    @Before
    fun setup() {
        mockMessenger = mockk(relaxed = true)
        mockContext = mockk(relaxed = true)
        mockLogic = mockk(relaxed = true)
        mockResult = mockk(relaxed = true)
        
        every { mockContext.applicationContext } returns mockContext
        PrayerAdhanMethodChannel.setLogic(mockLogic)
    }

    @Test
    fun `register sets method call handler and delegates to logic`() {
        val handlerSlot = slot<MethodChannel.MethodCallHandler>()
        mockkConstructor(MethodChannel::class)
        every { anyConstructed<MethodChannel>().setMethodCallHandler(capture(handlerSlot)) } returns Unit
        
        PrayerAdhanMethodChannel.register(mockMessenger, mockContext)
        
        val call = MethodCall("testMethod", mapOf("arg" to "value"))
        handlerSlot.captured.onMethodCall(call, mockResult)
        
        verify { mockLogic.handleMethodCall("testMethod", any(), any()) }
        
        unmockkConstructor(MethodChannel::class)
    }

    @Test
    fun `notifyNotificationTapped buffers if channel not registered and flushes on register`() {
        val prayerKey = "fajr"
        val payload = "{}"
        
        PrayerAdhanMethodChannel.resetForTesting()
        
        // 1. Notify before register
        PrayerAdhanMethodChannel.notifyNotificationTapped(prayerKey, payload)
        
        // 2. Register
        mockkConstructor(MethodChannel::class)
        every { anyConstructed<MethodChannel>().setMethodCallHandler(any()) } returns Unit
        every { anyConstructed<MethodChannel>().invokeMethod(any(), any()) } returns Unit
        
        PrayerAdhanMethodChannel.register(mockMessenger, mockContext)
        
        // 3. Verify it was flushed
        verify { 
            anyConstructed<MethodChannel>().invokeMethod("onNotificationTapped", mapOf(
                "prayer_key" to prayerKey,
                "payload" to payload
            ))
        }
        
        unmockkConstructor(MethodChannel::class)
    }
}
