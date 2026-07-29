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
}
