package com.tilawa.app.prayer

import androidx.work.ListenableWorker.Result
import org.junit.Test
import org.junit.Assert.*

class WatchdogLogicTest {
    private val logic = WatchdogLogic()

    @Test
    fun `handleComplete success`() {
        val result = logic.handleComplete(true, false, "Done", "None")
        assertEquals(Result.success(), result)
    }

    @Test
    fun `handleComplete retryable failure`() {
        val result = logic.handleComplete(false, true, "Failed but retry", "None")
        assertEquals(Result.retry(), result)
    }

    @Test
    fun `handleComplete fatal failure`() {
        val result = logic.handleComplete(false, false, "Fatal", "None")
        assertEquals(Result.failure(), result)
    }

    @Test
    fun `handleComplete null values default to failure`() {
        val result = logic.handleComplete(null, null, null, null)
        assertEquals(Result.failure(), result)
    }
}
