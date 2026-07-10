package com.tilawa.app.prayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class AdhanStartGateTest {

    private val gate = AdhanStartGate(windowMs = 60_000L)

    @Test
    fun `first start for an event is accepted with a session id`() {
        val sessionId = gate.tryStart("fajr", 1_000L, nowMs = 10_000L)

        assertNotNull(sessionId)
    }

    @Test
    fun `same event within the window is rejected even after playback ended`() {
        gate.tryStart("fajr", 1_000L, nowMs = 10_000L)

        assertNull(
            "Re-delivered alarm for the same prayer/time must not start a second session",
            gate.tryStart("fajr", 1_000L, nowMs = 40_000L),
        )
    }

    @Test
    fun `same event after the window is accepted again`() {
        gate.tryStart("fajr", 1_000L, nowMs = 10_000L)

        assertNotNull(gate.tryStart("fajr", 1_000L, nowMs = 80_000L))
    }

    @Test
    fun `different scheduled time is a different event and starts immediately`() {
        gate.tryStart("fajr", 1_000L, nowMs = 10_000L)

        assertNotNull(gate.tryStart("fajr", 2_000L, nowMs = 10_001L))
    }

    @Test
    fun `different prayer is a different event and starts immediately`() {
        gate.tryStart("dhuhr", 1_000L, nowMs = 10_000L)

        assertNotNull(gate.tryStart("asr", 1_000L, nowMs = 10_001L))
    }

    @Test
    fun `events without identity are never deduplicated`() {
        assertNotNull(gate.tryStart("", 0L, nowMs = 10_000L))
        assertNotNull(gate.tryStart("", 0L, nowMs = 10_001L))
    }

    @Test
    fun `session ids are unique per accepted start`() {
        val first = gate.tryStart("fajr", 1_000L, nowMs = 10_000L)
        val second = gate.tryStart("fajr", 1_000L, nowMs = 80_000L)

        assertNotEquals(first, second)
    }

    @Test
    fun `session id carries the event identity for log correlation`() {
        val sessionId = gate.tryStart("maghrib", 123L, nowMs = 10_000L)

        assertEquals(true, sessionId!!.contains("maghrib"))
        assertEquals(true, sessionId.contains("123"))
    }
}
