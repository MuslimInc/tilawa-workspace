package com.tilawa.app.widget.athkar

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

/**
 * Per-widget-instance advance progress: (periodKey, item index). Progress is
 * keyed by appWidgetId so two placed instances advance independently
 * (spec 041, US3 independent test), and resets implicitly when the stored
 * periodKey no longer matches the current window occurrence.
 */
internal class AthkarProgressStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun readPeriodKey(appWidgetId: Int): String? =
        prefs.getString("period_$appWidgetId", null)

    fun readIndex(appWidgetId: Int): Int = prefs.getInt("index_$appWidgetId", 0)

    fun write(appWidgetId: Int, periodKey: String, index: Int) {
        prefs.edit {
            putString("period_$appWidgetId", periodKey)
            putInt("index_$appWidgetId", index)
        }
    }

    fun clear(appWidgetId: Int) {
        prefs.edit {
            remove("period_$appWidgetId")
            remove("index_$appWidgetId")
        }
    }

    companion object {
        private const val PREFS_NAME = "athkar_widget_progress"
    }
}
