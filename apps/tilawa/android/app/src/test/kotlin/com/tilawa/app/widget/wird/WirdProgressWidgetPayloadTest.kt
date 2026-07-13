package com.tilawa.app.widget.wird

import android.os.Build
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class WirdProgressWidgetPayloadTest {

    /** Mirrors the exact JSON the Flutter adapter emits, timestamps included. */
    private fun validJson(): JSONObject = JSONObject(
        """
        {
          "schemaVersion": 1,
          "locale": "ar",
          "textDirection": "rtl",
          "localizedTitle": "وِرد اليوم",
          "localizedSubtitle": "أُنجز ١٢ من ٢٠ صفحة · المتبقي ٨",
          "formattedAssignedAmount": "٢٠",
          "formattedCompletedAmount": "١٢",
          "formattedRemainingAmount": "٨",
          "progressValue": 0.6,
          "accessibilityLabel": "وِرد اليوم. أُنجز ١٢ من ٢٠ صفحة",
          "action": "openTodayWird",
          "generatedAt": "2026-07-12T09:30:00.000",
          "expiresAt": "2026-07-13T00:00:00.000",
          "isStale": false
        }
        """.trimIndent(),
    )

    @Test
    fun `parses a complete payload and ignores envelope-owned timestamps`() {
        val payload = WirdProgressWidgetPayload.parse(validJson())
        assertNotNull(payload)
        assertEquals("ar", payload!!.locale)
        assertEquals(WirdWidgetTextDirection.RTL, payload.textDirection)
        assertEquals(WirdWidgetAction.OPEN_TODAY_WIRD, payload.action)
        assertEquals("٢٠", payload.formattedAssignedAmount)
        assertEquals("٨", payload.formattedRemainingAmount)
        assertEquals(0.6, payload.progressValue, 1e-9)
    }

    @Test
    fun `decodes the no-plan setup action`() {
        val json = validJson()
            .put("action", "createPlan")
            .put("textDirection", "ltr")
            .put("progressValue", 0.0)
        val payload = WirdProgressWidgetPayload.parse(json)
        assertNotNull(payload)
        assertEquals(WirdWidgetAction.CREATE_PLAN, payload!!.action)
        assertEquals(WirdWidgetTextDirection.LTR, payload.textDirection)
    }

    @Test
    fun `rejects an unknown action`() {
        assertNull(WirdProgressWidgetPayload.parse(validJson().put("action", "openKhatma")))
    }

    @Test
    fun `rejects an unknown text direction`() {
        assertNull(WirdProgressWidgetPayload.parse(validJson().put("textDirection", "auto")))
    }

    @Test
    fun `rejects an out-of-range or missing progress value`() {
        assertNull(WirdProgressWidgetPayload.parse(validJson().put("progressValue", 1.5)))
        assertNull(WirdProgressWidgetPayload.parse(validJson().put("progressValue", -0.1)))
        assertNull(WirdProgressWidgetPayload.parse(validJson().apply { remove("progressValue") }))
    }

    @Test
    fun `rejects blank required strings`() {
        assertNull(WirdProgressWidgetPayload.parse(validJson().put("locale", "")))
        assertNull(WirdProgressWidgetPayload.parse(validJson().put("localizedSubtitle", "")))
        assertNull(WirdProgressWidgetPayload.parse(validJson().put("formattedRemainingAmount", "")))
    }
}
