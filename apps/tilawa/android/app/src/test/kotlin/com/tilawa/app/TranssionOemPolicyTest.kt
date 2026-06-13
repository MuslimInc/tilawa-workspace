package com.tilawa.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TranssionOemPolicyTest {

    @Test
    fun `isTranssionDevice matches Infinix manufacturer`() {
        assertTrue(TranssionOemPolicy.isTranssionDevice(manufacturer = "INFINIX", brand = ""))
    }

    @Test
    fun `isTranssionDevice matches Tecno brand`() {
        assertTrue(TranssionOemPolicy.isTranssionDevice(manufacturer = "foo", brand = "Tecno"))
    }

    @Test
    fun `isTranssionDevice ignores other OEMs`() {
        assertFalse(
            TranssionOemPolicy.isTranssionDevice(manufacturer = "Samsung", brand = "samsung"),
        )
    }
}
