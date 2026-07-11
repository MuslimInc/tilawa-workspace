package com.tilawa.app.widget.ayah

import org.json.JSONObject

/**
 * Parsed payload of an Ayah of the Day snapshot (spec 041, US2). The verse
 * arrives as pre-rendered QCF PNG artifacts (one per theme) written by the
 * Flutter repository into the app's files directory.
 */
internal data class AyahWidgetPayload(
    val dateKey: String,
    val surahNumber: Int,
    val ayahNumber: Int,
    val pageNumber: Int,
    val caption: String,
    val imagePathLight: String,
    val imagePathDark: String,
) {
    companion object {
        /** Returns null when any required field is missing or invalid. */
        fun parse(payload: JSONObject): AyahWidgetPayload? {
            val dateKey = payload.optString("dateKey")
            val surah = payload.optInt("surahNumber", 0)
            val ayah = payload.optInt("ayahNumber", 0)
            val page = payload.optInt("pageNumber", 0)
            val caption = payload.optString("caption")
            val light = payload.optString("imagePathLight")
            val dark = payload.optString("imagePathDark")
            if (dateKey.isBlank() || light.isBlank() || dark.isBlank()) return null
            if (surah !in 1..114 || ayah < 1 || page !in 1..604) return null
            return AyahWidgetPayload(
                dateKey = dateKey,
                surahNumber = surah,
                ayahNumber = ayah,
                pageNumber = page,
                caption = caption,
                imagePathLight = light,
                imagePathDark = dark,
            )
        }
    }
}
