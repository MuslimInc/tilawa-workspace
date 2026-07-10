package com.tilawa.app.prayer.widget

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

/**
 * Persistence for the widget's prayer-times snapshot. Plain
 * [SharedPreferences] so [PrayerTimesWidgetProvider] can re-render after
 * reboot / launcher restart / app update without a Dart isolate (spec 041,
 * FR-010).
 */
internal class PrayerWidgetStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun readSnapshot(): PrayerWidgetSnapshot? =
        PrayerWidgetSnapshot.parse(prefs.getString(KEY_SNAPSHOT_JSON, null))

    fun writeSnapshotJson(json: String) {
        prefs.edit { putString(KEY_SNAPSHOT_JSON, json) }
    }

    companion object {
        private const val PREFS_NAME = "prayer_widget_store"
        private const val KEY_SNAPSHOT_JSON = "snapshot_json_v1"
    }
}
