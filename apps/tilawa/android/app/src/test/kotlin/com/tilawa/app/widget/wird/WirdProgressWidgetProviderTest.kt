package com.tilawa.app.widget.wird

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.test.core.app.ApplicationProvider
import com.tilawa.app.R
import com.tilawa.app.widget.WidgetSnapshotStore
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class WirdProgressWidgetProviderTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `missing snapshot renders a non-blank setup state`() {
        val manager = AppWidgetManager.getInstance(context)
        val widgetId = Shadows.shadowOf(manager).createWidget(
            WirdProgressWidgetProvider::class.java,
            R.layout.widget_wird_compact,
        )

        WirdProgressWidgetProvider().onUpdate(context, manager, intArrayOf(widgetId))
    }

    @Test
    fun `valid and stale snapshots render across refresh and resize`() {
        assertTrue(
            WidgetSnapshotStore(context).write(
                """
                {
                  "schemaVersion": 1,
                  "widgetType": "wird",
                  "generatedAtMs": 1000,
                  "validUntilMs": 2000,
                  "payload": {
                    "schemaVersion": 1,
                    "locale": "ar",
                    "textDirection": "rtl",
                    "localizedTitle": "ورد اليوم",
                    "localizedSubtitle": "٨ صفحات متبقية",
                    "formattedAssignedAmount": "٢٠",
                    "formattedCompletedAmount": "١٢",
                    "formattedRemainingAmount": "٨",
                    "progressValue": 0.6,
                    "accessibilityLabel": "ورد اليوم، بقي ٨ صفحات",
                    "action": "openTodayWird"
                  }
                }
                """.trimIndent(),
            ),
        )
        val manager = AppWidgetManager.getInstance(context)
        val widgetId = Shadows.shadowOf(manager).createWidget(
            WirdProgressWidgetProvider::class.java,
            R.layout.widget_wird_compact,
        )
        val provider = WirdProgressWidgetProvider()

        provider.onReceive(context, Intent(WirdProgressWidgetProvider.ACTION_REFRESH))
        provider.onAppWidgetOptionsChanged(
            context,
            manager,
            widgetId,
            Bundle().apply {
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 300)
            },
        )
    }
}
