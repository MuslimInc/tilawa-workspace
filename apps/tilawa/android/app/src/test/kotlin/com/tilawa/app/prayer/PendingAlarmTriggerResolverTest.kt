package com.tilawa.app.prayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.Calendar
import java.util.TimeZone

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [33])
class PendingAlarmTriggerResolverTest {
    @Test
    fun `legacy entry without wall clock keeps stored trigger`() {
        val entry =
            AlarmMetadata(
                id = 1,
                name = "fajr",
                key = "fajr",
                triggerMs = 1_700_000_000_000L,
                sound = "adhan_fajr",
            )

        assertEquals(
            1_700_000_000_000L,
            PendingAlarmTriggerResolver.resolveTriggerMs(entry),
        )
    }

    @Test
    fun `wall clock rebuilds trigger for current timezone`() {
        val zone = TimeZone.getTimeZone("America/New_York")
        val entry =
            AlarmMetadata(
                id = 2,
                name = "dhuhr",
                key = "dhuhr",
                triggerMs = 0L, // intentionally stale absolute millis
                sound = "adhan",
                year = 2026,
                month = 3,
                day = 8,
                hour = 12,
                minute = 30,
            )

        val resolved = PendingAlarmTriggerResolver.resolveTriggerMs(entry, zone)
        val calendar = Calendar.getInstance(zone).apply {
            set(Calendar.MILLISECOND, 0)
            set(2026, Calendar.MARCH, 8, 12, 30, 0)
        }

        assertEquals(calendar.timeInMillis, resolved)
        assertNotEquals(0L, resolved)
    }

    @Test
    fun `parse and serialize round-trip keeps wall clock fields`() {
        val json =
            """
            [{"id":3,"name":"asr","key":"asr","trigger":123,"sound":"adhan",
              "year":2026,"month":11,"day":1,"hour":15,"minute":5}]
            """.trimIndent()

        val parsed = BootLogic.parsePendingAlarms(json)
        assertEquals(1, parsed.size)
        assertEquals(2026, parsed[0].year)
        assertEquals(11, parsed[0].month)
        assertEquals(1, parsed[0].day)
        assertEquals(15, parsed[0].hour)
        assertEquals(5, parsed[0].minute)

        val serialized = BootLogic.serializePendingAlarms(parsed)
        val again = BootLogic.parsePendingAlarms(serialized)
        assertEquals(parsed[0], again[0])
    }
}
