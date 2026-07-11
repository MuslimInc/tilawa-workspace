package com.tilawa.app.widget

import android.content.Context
import android.content.SharedPreferences

/** Stores only snapshots that satisfy the shared versioned envelope contract. */
internal class WidgetSnapshotStore(context: Context) {
    private val preferences: SharedPreferences =
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    fun read(widgetType: WidgetType): WidgetSnapshotEnvelope? {
        val json = preferences.getString(key(widgetType), null) ?: return null
        return WidgetSnapshotEnvelope.parse(json)
    }

    fun write(json: String): Boolean {
        val snapshot = WidgetSnapshotEnvelope.parse(json) ?: return false
        return preferences.edit()
            .putString(key(snapshot.widgetType), json)
            .commit()
    }

    private fun key(widgetType: WidgetType): String =
        "${widgetType.wireName}_snapshot_v${WidgetSnapshotEnvelope.SCHEMA_VERSION}"

    companion object {
        private const val PREFERENCES_NAME = "islamic_widget_snapshots"
    }
}
