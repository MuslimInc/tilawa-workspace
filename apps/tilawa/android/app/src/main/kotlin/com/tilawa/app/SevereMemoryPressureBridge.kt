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
 * Deliberately ignores:
 * - [ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN]: OEMs such as OPPO fire that on
 *   every lock; eviction then only hurts unlock frames (see quran_image reader
 *   memory-pressure guard).
 * - [ComponentCallbacks2.TRIM_MEMORY_BACKGROUND]: normal "app entered LRU"
 *   signal on background/lock. Treating it as severe cleared Flutter's image
 *   cache while invisible, forcing a full re-decode on the next resume frame
 *   and regressing FLUTTER-9 on OPPO CPH2529 (Sentry level=40 breadcrumbs).
 *
 * Registration is process-scoped (Application [ComponentCallbacks2]). Activity
 * destroy only detaches the MethodChannel so mid-boot Activity recreate cannot
 * miss a RUNNING_* / COMPLETE trim.
 */
internal class SevereMemoryPressureBridge(
    private val log: (String) -> Unit = { message ->
        Log.d(TAG, message)
    },
) : ComponentCallbacks2 {
    @Volatile
    private var channel: MethodChannel? = null

    private var registered = false

    @Volatile
    private var pendingSevereLevel: Int? = null

    @Volatile
    private var pendingSevereReason: String? = null

    fun attachChannel(methodChannel: MethodChannel) {
        channel = methodChannel
        val level = pendingSevereLevel
        val reason = pendingSevereReason
        if (level != null && reason != null) {
            pendingSevereLevel = null
            pendingSevereReason = null
            log("flushing pending severe reason=$reason level=$level")
            invokeSevere(methodChannel, level, reason)
        }
    }

    /** Clears the Dart channel without unregistering Application callbacks. */
    fun detachChannel() {
        channel = null
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
        pendingSevereLevel = null
        pendingSevereReason = null
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
            pendingSevereLevel = level
            pendingSevereReason = reason
            log("channel not ready; queued pending severe")
            return
        }
        invokeSevere(activeChannel, level, reason)
    }

    private fun invokeSevere(
        activeChannel: MethodChannel,
        level: Int,
        reason: String,
    ) {
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
                level == ComponentCallbacks2.TRIM_MEMORY_MODERATE ||
                level == ComponentCallbacks2.TRIM_MEMORY_COMPLETE
        }
    }
}
