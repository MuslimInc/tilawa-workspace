package com.tilawa.app.prayer

import androidx.work.ListenableWorker.Result
import org.junit.Assert.assertEquals
import org.junit.Test

class WatchdogResultMapperTest {

    @Test
    fun `maps success to success`() {
        assertEquals(Result.success(), WatchdogResultMapper.map(success = true, retryable = false))
        assertEquals(Result.success(), WatchdogResultMapper.map(success = true, retryable = true))
    }

    @Test
    fun `maps failure and retryable to retry`() {
        assertEquals(Result.retry(), WatchdogResultMapper.map(success = false, retryable = true))
    }

    @Test
    fun `maps failure and not retryable to failure`() {
        assertEquals(Result.failure(), WatchdogResultMapper.map(success = false, retryable = false))
    }
}
