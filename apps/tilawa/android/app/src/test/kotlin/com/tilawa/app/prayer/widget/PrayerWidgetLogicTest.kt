package com.tilawa.app.prayer.widget

import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Contract tests for the widget's pure state resolution (spec 041, P1):
 * next-prayer selection, tomorrow-Fajr rollover, staleness, and snapshot
 * parsing of malformed input.
 *
 * Robolectric provides the real `org.json` implementation (the plain-JVM
 * android.jar stubs would make every parse return null).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class PrayerWidgetLogicTest {

    // Day 1: fajr=1000, sunrise=2000, dhuhr=3000, asr=4000, maghrib=5000, isha=6000
    private val day1 = PrayerWidgetDay(
        fajrMs = 1_000L,
        sunriseMs = 2_000L,
        dhuhrMs = 3_000L,
        asrMs = 4_000L,
        maghribMs = 5_000L,
        ishaMs = 6_000L,
    )
    private val day2 = PrayerWidgetDay(
        fajrMs = 11_000L,
        sunriseMs = 12_000L,
        dhuhrMs = 13_000L,
        asrMs = 14_000L,
        maghribMs = 15_000L,
        ishaMs = 16_000L,
    )

    private fun snapshot(vararg days: PrayerWidgetDay) = PrayerWidgetSnapshot(
        updatedAtMs = 500L,
        locationName = "Cairo",
        days = days.toList(),
    )

    @Test
    fun `before fajr the next prayer is fajr`() {
        val state = PrayerWidgetLogic.resolveState(snapshot(day1, day2), nowMs = 500L)!!
        assertEquals(PrayerWidgetDay.KEY_FAJR, state.nextPrayerKey)
        assertEquals(1_000L, state.nextPrayerTimeMs)
        assertEquals(day1, state.day)
        assertFalse(state.isStale)
    }

    @Test
    fun `between dhuhr and asr the next prayer is asr`() {
        val state = PrayerWidgetLogic.resolveState(snapshot(day1, day2), nowMs = 3_500L)!!
        assertEquals(PrayerWidgetDay.KEY_ASR, state.nextPrayerKey)
        assertEquals(4_000L, state.nextPrayerTimeMs)
    }

    @Test
    fun `sunrise is never selected as the next prayer`() {
        // Just after fajr, before sunrise — must skip to dhuhr, not sunrise.
        val state = PrayerWidgetLogic.resolveState(snapshot(day1), nowMs = 1_500L)!!
        assertEquals(PrayerWidgetDay.KEY_DHUHR, state.nextPrayerKey)
    }

    @Test
    fun `after isha rolls over to tomorrow's fajr`() {
        val state = PrayerWidgetLogic.resolveState(snapshot(day1, day2), nowMs = 7_000L)!!
        assertEquals(PrayerWidgetDay.KEY_FAJR, state.nextPrayerKey)
        assertEquals(11_000L, state.nextPrayerTimeMs)
        assertEquals(day2, state.day)
    }

    @Test
    fun `all prayers past yields stale state with last known day`() {
        val state = PrayerWidgetLogic.resolveState(snapshot(day1, day2), nowMs = 99_000L)!!
        assertNull(state.nextPrayerKey)
        assertNull(state.nextPrayerTimeMs)
        assertTrue(state.isStale)
        assertEquals(day2, state.day)
    }

    @Test
    fun `next refresh fires just after the prayer boundary`() {
        val state = PrayerWidgetLogic.resolveState(snapshot(day1), nowMs = 500L)!!
        val refreshAt = PrayerWidgetLogic.nextRefreshAtMs(state)!!
        assertTrue("refresh must be after the boundary", refreshAt > 1_000L)
    }

    @Test
    fun `stale state schedules no boundary refresh`() {
        val state = PrayerWidgetLogic.resolveState(snapshot(day1), nowMs = 99_000L)!!
        assertNull(PrayerWidgetLogic.nextRefreshAtMs(state))
    }

    // --- Snapshot parsing ---

    @Test
    fun `parse round-trips a valid snapshot`() {
        val json = """
            {"version":1,"updatedAtMs":500,"locationName":"Cairo","days":[
              {"fajr":1000,"sunrise":2000,"dhuhr":3000,"asr":4000,"maghrib":5000,"isha":6000}
            ]}
        """.trimIndent()
        val parsed = PrayerWidgetSnapshot.parse(json)
        assertNotNull(parsed)
        assertEquals("Cairo", parsed!!.locationName)
        assertEquals(1, parsed.days.size)
        assertEquals(1_000L, parsed.days.first().fajrMs)
    }

    @Test
    fun `parse rejects malformed input`() {
        assertNull(PrayerWidgetSnapshot.parse(null))
        assertNull(PrayerWidgetSnapshot.parse(""))
        assertNull(PrayerWidgetSnapshot.parse("not json"))
        assertNull(PrayerWidgetSnapshot.parse("{}"))
        assertNull(PrayerWidgetSnapshot.parse("""{"version":99,"days":[]}"""))
        assertNull(PrayerWidgetSnapshot.parse("""{"version":1,"days":[]}"""))
        // Day entries missing required times are skipped.
        assertNull(
            PrayerWidgetSnapshot.parse("""{"version":1,"days":[{"fajr":0,"isha":0}]}"""),
        )
    }

    @Test
    fun `parse sorts days chronologically`() {
        val json = """
            {"version":1,"days":[
              {"fajr":11000,"sunrise":12000,"dhuhr":13000,"asr":14000,"maghrib":15000,"isha":16000},
              {"fajr":1000,"sunrise":2000,"dhuhr":3000,"asr":4000,"maghrib":5000,"isha":6000}
            ]}
        """.trimIndent()
        val parsed = PrayerWidgetSnapshot.parse(json)!!
        assertEquals(1_000L, parsed.days.first().fajrMs)
        assertEquals(11_000L, parsed.days.last().fajrMs)
    }
}
