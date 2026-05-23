package com.tilawa.app.auth

import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class GoogleSignInPrepareBridgeTest {

    @Before
    fun setUp() {
        GoogleSignInPrepareBridge.resetForTesting()
    }

    @After
    fun tearDown() {
        GoogleSignInPrepareBridge.resetForTesting()
    }

    @Test
    fun `prepare with blank client id completes false without preparing`() {
        var result: Boolean? = null

        GoogleSignInPrepareBridge.prepare(
            ApplicationProvider.getApplicationContext(),
            "   ",
        ) { result = it }

        assertEquals(false, result)
        assertFalse(GoogleSignInPrepareBridge.hasPreparedResponseForTesting())
    }

    @Test
    fun `prepare on API below 34 completes true without cached response`() {
        var result: Boolean? = null

        GoogleSignInPrepareBridge.prepare(
            ApplicationProvider.getApplicationContext(),
            "test-client-id.apps.googleusercontent.com",
        ) { result = it }

        Shadows.shadowOf(Looper.getMainLooper()).idle()

        assertEquals(true, result)
        assertFalse(GoogleSignInPrepareBridge.hasPreparedResponseForTesting())
    }

    @Test
    fun `prepare skips second call while first is in flight`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        var first: Boolean? = null
        var second: Boolean? = null

        GoogleSignInPrepareBridge.prepare(
            context,
            "client-id.apps.googleusercontent.com",
        ) { first = it }
        GoogleSignInPrepareBridge.prepare(
            context,
            "client-id.apps.googleusercontent.com",
        ) { second = it }
        Shadows.shadowOf(Looper.getMainLooper()).idle()

        assertEquals(true, first)
        assertEquals(true, second)
    }

    @Test
    fun `clear resets prepared response state`() {
        GoogleSignInPrepareBridge.clear()

        assertFalse(GoogleSignInPrepareBridge.hasPreparedResponseForTesting())
    }
}
