package com.tilawa.app.prayer

import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import java.util.Locale

internal object NotificationLocaleHelper {
    fun normalizeLanguageCode(languageCode: String?): String {
        return when (languageCode?.lowercase()) {
            "ar" -> "ar"
            else -> "en"
        }
    }

    fun localizedResources(base: Context, languageCode: String?): Resources {
        val locale = Locale(normalizeLanguageCode(languageCode))
        val config = Configuration(base.resources.configuration)
        config.setLocale(locale)
        return base.createConfigurationContext(config).resources
    }
}
