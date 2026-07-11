package com.tilawa.app.widget

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class WidgetSnapshotStoreTest {
    private lateinit var context: Context
    private lateinit var store: WidgetSnapshotStore

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences("islamic_widget_snapshots", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
        store = WidgetSnapshotStore(context)
    }

    @Test
    fun validSnapshotIsStoredForItsWidgetType() {
        assertTrue(store.write(validAyahSnapshot(generatedAtMs = 1000L)))

        val stored = store.read(WidgetType.AYAH)
        assertEquals(WidgetType.AYAH, stored?.widgetType)
        assertEquals(1000L, stored?.generatedAtMs)
        assertEquals(1, stored?.payload?.getInt("surahNumber"))
        assertNull(store.read(WidgetType.PRAYER))
    }

    @Test
    fun malformedReplacementKeepsLastValidSnapshot() {
        assertTrue(store.write(validAyahSnapshot(generatedAtMs = 1000L)))

        assertFalse(store.write("{not-json"))

        assertEquals(1000L, store.read(WidgetType.AYAH)?.generatedAtMs)
    }

    @Test
    fun unsupportedSchemaKeepsLastValidSnapshot() {
        assertTrue(store.write(validAyahSnapshot(generatedAtMs = 1000L)))
        val unsupported = validAyahSnapshot(generatedAtMs = 2000L)
            .replace("\"schemaVersion\":1", "\"schemaVersion\":2")

        assertFalse(store.write(unsupported))

        assertEquals(1000L, store.read(WidgetType.AYAH)?.generatedAtMs)
    }

    private fun validAyahSnapshot(generatedAtMs: Long): String =
        """{
            "schemaVersion":1,
            "widgetType":"ayah",
            "generatedAtMs":$generatedAtMs,
            "validUntilMs":3000,
            "payload":{"surahNumber":1,"ayahNumber":1,"pageNumber":1}
        }""".trimIndent()
}
