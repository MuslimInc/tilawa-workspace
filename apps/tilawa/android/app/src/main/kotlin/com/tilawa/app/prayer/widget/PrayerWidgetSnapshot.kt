package com.tilawa.app.prayer.widget

import org.json.JSONObject

/**
 * Immutable snapshot of upcoming prayer times pushed from Flutter for the
 * home-screen widget. Written by `MethodChannelLogic` when the daily schedule
 * pass runs; read by [PrayerTimesWidgetProvider] with no Dart isolate needed.
 *
 * JSON shape (version 1):
 * ```json
 * {
 *   "version": 1,
 *   "updatedAtMs": 1720000000000,
 *   "locationName": "Cairo",
 *   "days": [
 *     {"fajr": ms, "sunrise": ms, "dhuhr": ms, "asr": ms,
 *      "maghrib": ms, "isha": ms}
 *   ]
 * }
 * ```
 */
internal data class PrayerWidgetDay(
    val fajrMs: Long,
    val sunriseMs: Long,
    val dhuhrMs: Long,
    val asrMs: Long,
    val maghribMs: Long,
    val ishaMs: Long,
) {
    /** The five prayers in chronological order as (key, epochMs) pairs. */
    val prayers: List<Pair<String, Long>>
        get() = listOf(
            KEY_FAJR to fajrMs,
            KEY_DHUHR to dhuhrMs,
            KEY_ASR to asrMs,
            KEY_MAGHRIB to maghribMs,
            KEY_ISHA to ishaMs,
        )

    /** Display rows in widget order (sunrise included, never a countdown target). */
    val displayRows: List<Pair<String, Long>>
        get() = listOf(
            KEY_FAJR to fajrMs,
            KEY_SUNRISE to sunriseMs,
            KEY_DHUHR to dhuhrMs,
            KEY_ASR to asrMs,
            KEY_MAGHRIB to maghribMs,
            KEY_ISHA to ishaMs,
        )

    companion object {
        const val KEY_FAJR = "fajr"
        const val KEY_SUNRISE = "sunrise"
        const val KEY_DHUHR = "dhuhr"
        const val KEY_ASR = "asr"
        const val KEY_MAGHRIB = "maghrib"
        const val KEY_ISHA = "isha"
    }
}

internal data class PrayerWidgetSnapshot(
    val updatedAtMs: Long,
    val locationName: String,
    val days: List<PrayerWidgetDay>,
) {
    companion object {
        const val SCHEMA_VERSION = 1

        /** Parses snapshot JSON. Returns null on malformed or empty input. */
        fun parse(json: String?): PrayerWidgetSnapshot? {
            if (json.isNullOrBlank()) return null
            return try {
                val root = JSONObject(json)
                if (root.optInt("version", -1) != SCHEMA_VERSION) return null
                val daysJson = root.optJSONArray("days") ?: return null
                val days = ArrayList<PrayerWidgetDay>(daysJson.length())
                for (i in 0 until daysJson.length()) {
                    val d = daysJson.optJSONObject(i) ?: continue
                    val fajr = d.optLong("fajr", 0L)
                    val isha = d.optLong("isha", 0L)
                    if (fajr <= 0L || isha <= 0L) continue
                    days.add(
                        PrayerWidgetDay(
                            fajrMs = fajr,
                            sunriseMs = d.optLong("sunrise", 0L),
                            dhuhrMs = d.optLong("dhuhr", 0L),
                            asrMs = d.optLong("asr", 0L),
                            maghribMs = d.optLong("maghrib", 0L),
                            ishaMs = isha,
                        ),
                    )
                }
                if (days.isEmpty()) return null
                PrayerWidgetSnapshot(
                    updatedAtMs = root.optLong("updatedAtMs", 0L),
                    locationName = root.optString("locationName", ""),
                    days = days.sortedBy { it.fajrMs },
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}
