package com.tilawa.app.widget

import org.json.JSONException
import org.json.JSONObject

internal enum class WidgetType(val wireName: String) {
    PRAYER("prayer"),
    AYAH("ayah"),
    ATHKAR("athkar"),
    HIJRI("hijri"),
    ;

    companion object {
        fun fromWireName(wireName: String): WidgetType? =
            entries.firstOrNull { it.wireName == wireName }
    }
}

internal data class WidgetSnapshotEnvelope(
    val widgetType: WidgetType,
    val generatedAtMs: Long,
    val validUntilMs: Long?,
    val payload: JSONObject,
) {
    companion object {
        const val SCHEMA_VERSION = 1

        fun parse(json: String): WidgetSnapshotEnvelope? {
            return try {
                val root = JSONObject(json)
                if (root.optInt("schemaVersion", -1) != SCHEMA_VERSION) return null
                val widgetType = WidgetType.fromWireName(root.optString("widgetType"))
                    ?: return null
                val generatedAtMs = root.optLong("generatedAtMs", 0L)
                if (generatedAtMs <= 0L) return null
                val validUntilMs = root.optLong("validUntilMs", 0L).takeIf { it > 0L }
                if (validUntilMs != null && validUntilMs < generatedAtMs) return null
                val payload = root.optJSONObject("payload") ?: return null
                WidgetSnapshotEnvelope(
                    widgetType = widgetType,
                    generatedAtMs = generatedAtMs,
                    validUntilMs = validUntilMs,
                    payload = payload,
                )
            } catch (_: JSONException) {
                null
            }
        }
    }
}
