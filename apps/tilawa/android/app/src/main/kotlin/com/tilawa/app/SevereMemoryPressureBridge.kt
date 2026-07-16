package com.tilawa.app

import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * Forwards **severe** Android memory callbacks to Dart so caches can shrink
 * before LMK kills the process (Sentry FLUTTER-9: AppExitInfo ANR after
 * LOW_MEMORY → Activity recreate).
 *
 * Deliberately ignores [ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN]: OEMs such
 * as OPPO fire that on every lock, and eviction then only hurts unlock frames
 * (see quran_image reader memory-pressure guard).
 */
internal class SevereMemoryPressureBridge(
    private val log: (String) -> Unit = { message ->
        Log.d(TAG, message)
    },
) : ComponentCallbacks2 {
    @Volatile
    private var channel: MethodChannel? = null

    private var registered = false

    fun attachChannel(methodChannel: MethodChannel) {
        channel = methodChannel
    }

    fun register(context: Context) {
        if (registered) {
            return
        }
        context.applicationContext.registerComponentCallbacks(this)
        registered = true
        log("registered ComponentCallbacks2")
    }

    fun unregister(context: Context) {
        if (!registered) {
            return
        }
        try {
            context.applicationContext.unregisterComponentCallbacks(this)
        } catch (error: IllegalArgumentException) {
            log("unregister failed: $error")
        }
        registered = false
        channel = null
    }

    override fun onTrimMemory(level: Int) {
        BootDeviceEventBreadcrumbs.recordTrimMemory(level)
        if (!isSevereTrimLevel(level)) {
            log("trim ignored (not severe) level=$level")
            return
        }
        notifySevere(level, reason = "trim")
    }

    @Suppress("DEPRECATION")
    override fun onLowMemory() {
        BootDeviceEventBreadcrumbs.recordLowMemory()
        @Suppress("DEPRECATION")
        notifySevere(ComponentCallbacks2.TRIM_MEMORY_COMPLETE, reason = "low_memory")
    }

    override fun onConfigurationChanged(newConfig: Configuration) = Unit

    private fun notifySevere(level: Int, reason: String) {
        log("severe memory pressure reason=$reason level=$level")
        val activeChannel = channel
        if (activeChannel == null) {
            log("channel not ready; breadcrumb only")
            return
        }
        try {
            activeChannel.invokeMethod(
                "severe",
                mapOf(
                    "level" to level,
                    "reason" to reason,
                ),
            )
        } catch (error: Throwable) {
            log("invokeMethod failed: $error")
        }
    }

    companion object {
        private const val TAG = "SevereMemoryPressure"
        const val CHANNEL = "com.tilawa.app/memory_pressure"

        /** Package-visible for unit tests. */
        @JvmStatic
        @Suppress("DEPRECATION")
        fun isSevereTrimLevel(level: Int): Boolean {
            return level == ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE ||
                level == ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW ||
                level == ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL ||
                level == ComponentCallbacks2.TRIM_MEMORY_BACKGROUND ||
                level == ComponentCallbacks2.TRIM_MEMORY_MODERATE ||
                level == ComponentCallbacks2.TRIM_MEMORY_COMPLETE
        }
    }
}

