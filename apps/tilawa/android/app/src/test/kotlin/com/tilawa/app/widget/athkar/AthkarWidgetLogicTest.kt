package com.tilawa.app.widget.athkar

import android.os.Build
import java.util.Calendar
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.json.JSONObject
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Window/periodKey/progress rules (spec 041, US3 / T027).
 *  Robolectric provides the real org.json implementation. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class AthkarWidgetLogicTest {

    private fun atLocal(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int = 0,
    ): Long = Calendar.getInstance().run {
        clear()
        set(year, month - 1, day, hour, minute, 0)
        timeInMillis
    }

    @Test
    fun `mid-morning resolves to morning with same-day key`() {
        val state = AthkarWidgetLogic.resolveState(atLocal(2026, 7, 11, 8, 30))
        assertEquals(AthkarPeriod.MORNING, state.period)
        assertEquals("M-2026-07-11", state.periodKey)
        assertEquals(atLocal(2026, 7, 11, 15), state.nextTransitionMs)
    }

    @Test
    fun `evening starts at 15`() {
        val state = AthkarWidgetLogic.resolveState(atLocal(2026, 7, 11, 15))
        assertEquals(AthkarPeriod.EVENING, state.period)
        assertEquals("E-2026-07-11", state.periodKey)
        assertEquals(atLocal(2026, 7, 12, 4), state.nextTransitionMs)
    }

    @Test
    fun `after midnight still belongs to previous evening`() {
        val state = AthkarWidgetLogic.resolveState(atLocal(2026, 7, 12, 2, 59))
        assertEquals(AthkarPeriod.EVENING, state.period)
        assertEquals("E-2026-07-11", state.periodKey)
        assertEquals(atLocal(2026, 7, 12, 4), state.nextTransitionMs)
    }

    @Test
    fun `morning and evening keys of the same day differ`() {
        val morning = AthkarWidgetLogic.resolveState(atLocal(2026, 7, 11, 9))
        val evening = AthkarWidgetLogic.resolveState(atLocal(2026, 7, 11, 20))
        assertNotEquals(morning.periodKey, evening.periodKey)
    }

    @Test
    fun `progress resets when the window occurrence changes`() {
        assertEquals(
            0,
            AthkarWidgetLogic.effectiveIndex(
                storedPeriodKey = "M-2026-07-10",
                storedIndex = 7,
                currentPeriodKey = "M-2026-07-11",
                setSize = 25,
            ),
        )
    }

    @Test
    fun `progress persists within the same window occurrence`() {
        assertEquals(
            7,
            AthkarWidgetLogic.effectiveIndex(
                storedPeriodKey = "M-2026-07-11",
                storedIndex = 7,
                currentPeriodKey = "M-2026-07-11",
                setSize = 25,
            ),
        )
    }

    @Test
    fun `stored index is clamped to a shrunken set`() {
        assertEquals(
            10,
            AthkarWidgetLogic.effectiveIndex(
                storedPeriodKey = "M-2026-07-11",
                storedIndex = 99,
                currentPeriodKey = "M-2026-07-11",
                setSize = 10,
            ),
        )
    }

    // --- Payload parsing ---

    @Test
    fun `parses both sets`() {
        val payload = AthkarWidgetPayload.parse(
            JSONObject(
                """
                {"morningTitle":"أذكار الصباح","eveningTitle":"أذكار المساء",
                 "morning":[{"text":"ذكر ١","count":3}],
                 "evening":[{"text":"ذكر ٢","count":1}]}
                """.trimIndent(),
            ),
        )
        assertNotNull(payload)
        assertEquals(1, payload!!.morning.size)
        assertEquals(3, payload.morning.first().count)
        assertEquals("أذكار المساء", payload.eveningTitle)
    }

    @Test
    fun `rejects payload with an empty set`() {
        assertNull(
            AthkarWidgetPayload.parse(
                JSONObject(
                    """{"morning":[{"text":"ذكر"}],"evening":[]}""",
                ),
            ),
        )
    }

    @Test
    fun `arabic digit conversion`() {
        assertEquals("٣/٢٥", AthkarWidgetProvider.arabicDigits("3/25"))
    }
}
