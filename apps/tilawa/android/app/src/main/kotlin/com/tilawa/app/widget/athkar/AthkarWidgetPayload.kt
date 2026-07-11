package com.tilawa.app.widget.athkar

import org.json.JSONArray
import org.json.JSONObject

internal data class AthkarWidgetItem(
    val text: String,
    val count: Int,
)

/**
 * Parsed payload of the athkar widget snapshot (spec 041, US3). Carries both
 * sets; the provider picks the applicable window by local time.
 */
internal data class AthkarWidgetPayload(
    val morningTitle: String,
    val eveningTitle: String,
    val morning: List<AthkarWidgetItem>,
    val evening: List<AthkarWidgetItem>,
) {
    companion object {
        /** Returns null when either set is missing or empty. */
        fun parse(payload: JSONObject): AthkarWidgetPayload? {
            val morning = parseItems(payload.optJSONArray("morning"))
            val evening = parseItems(payload.optJSONArray("evening"))
            if (morning.isEmpty() || evening.isEmpty()) return null
            return AthkarWidgetPayload(
                morningTitle = payload.optString("morningTitle"),
                eveningTitle = payload.optString("eveningTitle"),
                morning = morning,
                evening = evening,
            )
        }

        private fun parseItems(array: JSONArray?): List<AthkarWidgetItem> {
            if (array == null) return emptyList()
            val items = ArrayList<AthkarWidgetItem>(array.length())
            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue
                val text = item.optString("text")
                if (text.isBlank()) continue
                items.add(
                    AthkarWidgetItem(
                        text = text,
                        count = item.optInt("count", 1).coerceAtLeast(1),
                    ),
                )
            }
            return items
        }
    }
}
