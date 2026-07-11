package com.tilawa.app.widget.ayah

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
class AyahWidgetPayloadTest {

    private fun validJson(): JSONObject = JSONObject(
        """
        {
          "dateKey": "2026-07-11",
          "surahNumber": 2,
          "ayahNumber": 152,
          "pageNumber": 23,
          "caption": "سورة البقرة · ١٥٢",
          "imagePathLight": "/data/app/files/ayah_light.png",
          "imagePathDark": "/data/app/files/ayah_dark.png"
        }
        """.trimIndent(),
    )

    @Test
    fun `parses a complete payload`() {
        val payload = AyahWidgetPayload.parse(validJson())
        assertNotNull(payload)
        assertEquals("2026-07-11", payload!!.dateKey)
        assertEquals(2, payload.surahNumber)
        assertEquals(152, payload.ayahNumber)
        assertEquals(23, payload.pageNumber)
        assertEquals("سورة البقرة · ١٥٢", payload.caption)
    }

    @Test
    fun `rejects missing image paths`() {
        val json = validJson().apply { remove("imagePathLight") }
        assertNull(AyahWidgetPayload.parse(json))
    }

    @Test
    fun `rejects out-of-range references`() {
        assertNull(AyahWidgetPayload.parse(validJson().put("surahNumber", 115)))
        assertNull(AyahWidgetPayload.parse(validJson().put("surahNumber", 0)))
        assertNull(AyahWidgetPayload.parse(validJson().put("pageNumber", 605)))
        assertNull(AyahWidgetPayload.parse(validJson().put("ayahNumber", 0)))
    }

    @Test
    fun `rejects blank date key`() {
        assertNull(AyahWidgetPayload.parse(validJson().put("dateKey", "")))
    }
}
