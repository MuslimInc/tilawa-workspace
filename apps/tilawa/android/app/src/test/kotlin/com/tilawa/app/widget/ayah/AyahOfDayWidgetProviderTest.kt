package com.tilawa.app.widget.ayah

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.tilawa.app.R
import com.tilawa.app.widget.WidgetSnapshotStore
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config

/** Lifecycle smoke tests for the Ayah provider (spec 041, T023). */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class AyahOfDayWidgetProviderTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `onUpdate with no snapshot renders empty state without crashing`() {
        val manager = AppWidgetManager.getInstance(context)
        val widgetId = Shadows.shadowOf(manager).createWidget(
            AyahOfDayWidgetProvider::class.java,
            R.layout.widget_ayah_of_day,
        )
        val provider = AyahOfDayWidgetProvider()
        // No snapshot written — must not throw (never-blank contract).
        provider.onUpdate(context, manager, intArrayOf(widgetId))
    }

    @Test
    fun `refresh action with stored snapshot renders without crashing`() {
        val stored = WidgetSnapshotStore(context).write(
            """
            {
              "schemaVersion": 1,
              "widgetType": "ayah",
              "generatedAtMs": 1000,
              "validUntilMs": ${System.currentTimeMillis() + 3_600_000},
              "payload": {
                "dateKey": "2026-07-11",
                "surahNumber": 2,
                "ayahNumber": 152,
                "pageNumber": 23,
                "caption": "سورة البقرة · ١٥٢",
                "imagePathLight": "/nonexistent/light.png",
                "imagePathDark": "/nonexistent/dark.png"
              }
            }
            """.trimIndent(),
        )
        assertTrue("snapshot must satisfy the envelope contract", stored)

        val provider = AyahOfDayWidgetProvider()
        // Missing artifact files degrade to the empty state — no crash.
        provider.onReceive(
            context,
            Intent(AyahOfDayWidgetProvider.ACTION_REFRESH),
        )
    }
}
