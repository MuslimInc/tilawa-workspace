package com.tilawa.app

import android.os.Build

/**
 * Transsion ROMs (Infinix, Tecno, Itel) can stack Credential Manager /
 * Play Services sign-in UI behind Flutter when using [RenderMode.surface].
 * [MainActivity] uses [RenderMode.texture] on all Android launches.
 */
object TranssionOemPolicy {
    private val TRANSSION_OEMS = setOf("infinix", "tecno", "itel")

    fun isTranssionDevice(
        manufacturer: String = Build.MANUFACTURER.orEmpty(),
        brand: String = Build.BRAND.orEmpty(),
    ): Boolean {
        val manufacturerLower = manufacturer.lowercase()
        val brandLower = brand.lowercase()
        return manufacturerLower in TRANSSION_OEMS || brandLower in TRANSSION_OEMS
    }
}
