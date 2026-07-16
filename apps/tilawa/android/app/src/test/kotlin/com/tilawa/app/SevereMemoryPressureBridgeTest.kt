package com.tilawa.app

import android.content.ComponentCallbacks2
import android.os.Build
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class SevereMemoryPressureBridgeTest {

    @Test
    fun `UI_HIDDEN is not severe so OEM lock noise is ignored`() {
        assertFalse(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN,
            ),
        )
    }

    @Test
    fun `RUNNING_CRITICAL and COMPLETE are severe`() {
        assertTrue(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
            ),
        )
        assertTrue(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_COMPLETE,
            ),
        )
        assertTrue(
            SevereMemoryPressureBridge.isSevereTrimLevel(
                ComponentCallbacks2.TRIM_MEMORY_BACKGROUND,
            ),
        )
    }
}
