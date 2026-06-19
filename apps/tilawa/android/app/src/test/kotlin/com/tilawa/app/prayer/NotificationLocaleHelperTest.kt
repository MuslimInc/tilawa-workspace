package com.tilawa.app.prayer

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class NotificationLocaleHelperTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `normalizeLanguageCode maps Arabic variants to ar`() {
        assertEquals("ar", NotificationLocaleHelper.normalizeLanguageCode("ar"))
        assertEquals("ar", NotificationLocaleHelper.normalizeLanguageCode("AR"))
    }

    @Test
    fun `normalizeLanguageCode defaults unknown codes to en`() {
        assertEquals("en", NotificationLocaleHelper.normalizeLanguageCode("en"))
        assertEquals("en", NotificationLocaleHelper.normalizeLanguageCode("fr"))
        assertEquals("en", NotificationLocaleHelper.normalizeLanguageCode(null))
    }

    @Test
    fun `localizedResources resolves Arabic strings when language is ar`() {
        val resources = NotificationLocaleHelper.localizedResources(context, "ar")
        val titleResId = resources.getIdentifier("adhan_notification_body", "string", context.packageName)
        assertTrue(titleResId != 0)
        val body = resources.getString(titleResId)
        assertTrue(body.contains("الأذان"))
    }

    @Test
    fun `localizedResources resolves English strings when language is en`() {
        val resources = NotificationLocaleHelper.localizedResources(context, "en")
        val titleResId = resources.getIdentifier("adhan_notification_body", "string", context.packageName)
        assertTrue(titleResId != 0)
        val body = resources.getString(titleResId)
        assertTrue(body.contains("Adhan"))
    }
}
