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

    @Test
    fun `test split storage migration and cleanup`() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        
        // Simulating legacy state in CPS
        val cpsPrefs = context.getSharedPreferences("prayer_adhan_alarms", android.content.Context.MODE_PRIVATE)
        cpsPrefs.edit().putString("pending_alarms_json", "old_json").apply()
        
        val storage = DefaultPrayerStorage(context)
        
        // Initially DPS should be empty
        assertNull(storage.getPendingAlarmsJson())
        
        // Writing to storage should move it to DPS and cleanup CPS
        storage.setPendingAlarmsJson("new_json")
        assertEquals("new_json", storage.getPendingAlarmsJson())
        assertFalse(cpsPrefs.contains("pending_alarms_json"))
    }
}
