package com.tilawa.app.prayer

import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class DefaultPrayerStorageTest {

    @Test
    fun `test needsReschedule lifecycle`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val storage = DefaultPrayerStorage(context)
        
        assertFalse(storage.needsReschedule())
        
        storage.setNeedsReschedule(true)
        assertTrue(storage.needsReschedule())
        
        storage.setNeedsReschedule(false)
        assertFalse(storage.needsReschedule())
    }
}
