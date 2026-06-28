package com.tilawa.app

import android.content.Intent
import android.os.Build
import io.sentry.Breadcrumb
import io.sentry.Hint
import io.sentry.Sentry
import io.sentry.SentryOptions
import io.sentry.transport.RateLimiter
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.concurrent.CopyOnWriteArrayList

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class BootDeviceEventBreadcrumbsTest {

    private val captured = CopyOnWriteArrayList<Breadcrumb>()

    @Before
    fun setup() {
        captured.clear()
        BootDeviceEventBreadcrumbs.resetForLaunch()
        Sentry.init { options: SentryOptions ->
            options.dsn = "https://public@sentry.io/1"
            options.isEnabled = true
            options.beforeBreadcrumb =
                SentryOptions.BeforeBreadcrumbCallback { breadcrumb: Breadcrumb, _: Hint ->
                    captured.add(breadcrumb)
                    breadcrumb
                }
        }
    }

    @After
    fun tearDown() {
        Sentry.close()
        captured.clear()
        BootDeviceEventBreadcrumbs.resetForLaunch()
    }

    @Test
    fun `record tags during_boot true while boot in progress`() {
        BootDeviceEventBreadcrumbs.record(Intent.ACTION_SHUTDOWN)

        assertEquals(1, captured.size)
        val breadcrumb = captured.single()
        assertEquals("boot.device.event", breadcrumb.category)
        assertEquals(Intent.ACTION_SHUTDOWN, breadcrumb.getData("action"))
        assertEquals(true, breadcrumb.getData("during_boot"))
    }

    @Test
    fun `record tags during_boot false after boot completes`() {
        BootDeviceEventBreadcrumbs.markBootComplete()
        BootDeviceEventBreadcrumbs.record(Intent.ACTION_AIRPLANE_MODE_CHANGED)

        assertEquals(1, captured.size)
        val breadcrumb = captured.single()
        assertEquals(Intent.ACTION_AIRPLANE_MODE_CHANGED, breadcrumb.getData("action"))
        assertEquals(false, breadcrumb.getData("during_boot"))
    }

    @Test
    fun `resetForLaunch restores boot in progress flag`() {
        BootDeviceEventBreadcrumbs.markBootComplete()
        assertFalse(BootDeviceEventBreadcrumbs.bootInProgress)

        BootDeviceEventBreadcrumbs.resetForLaunch()
        assertTrue(BootDeviceEventBreadcrumbs.bootInProgress)
    }
}
