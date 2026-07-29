package com.tilawa.app

import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import android.util.Log
import androidx.annotation.VisibleForTesting
import io.flutter.plugin.common.MethodChannel

/**
 * Forwards severe Android memory callbacks to Dart so caches can shrink
 * before LMK kills the process (Sentry FLUTTER-9: AppExitInfo ANR after
 * LOW_MEMORY → Activity recreate).
 *
 * Deliberately ignores:
 * - ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN: OEMs such as OPPO fire that on
 *   every lock; eviction then only hurts unlock frames (see quran_image reader
 *   memory-pressure guard).
 * - ComponentCallbacks2.TRIM_MEMORY_BACKGROUND: normal "app entered LRU"
 *   signal on background/lock. Treating it as severe triggered Tilawa's
 *   aggressive eviction (ImageCache.clearLiveImages, Quran decoded-cache
 *   release, lowered ceiling) on unlock and regressed FLUTTER-9 on CPH2529.
 *
 * Scope of this bridge: stops Tilawa's extra severe path for BACKGROUND.
 * Flutter's embedding still forwards many trim levels (including BACKGROUND)
 * via SystemChannel → PaintingBinding.handleMemoryPressure →
 * imageCache.clear(). That built-in clear is intentional residual risk;
 * production CPH2529 telemetry must confirm it alone does not reproduce the
 * ANR. On API 34+ Android no longer delivers the legacy RUNNING_MODERATE /
 * RUNNING_LOW / RUNNING_CRITICAL / MODERATE / COMPLETE levels to apps, so
 * this custom path is mostly inert there — an explicit trade-off vs OEM
 * unlock jank.
 *
 * Process ownership: one Application-registered instance for the process.
 * Activities only attach/detach their Dart MethodChannel with an owner token
 * so a destroyed Activity cannot clear a newer Activity's channel.
 */
internal class SevereMemoryPressureBridge private constructor(
    private val log: (String) -> Unit,
) : ComponentCallbacks2 {
    @Volatile
    private var channel: MethodChannel? = null

    @Volatile
    private var channelOwner: Any? = null

    @Volatile
    private var registered = false

    @Volatile
    private var pendingSevereLevel: Int? = null

    @Volatile
    private var pendingSevereReason: String? = null

    fun attachChannel(owner: Any, methodChannel: MethodChannel) {
        channelOwner = owner
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

    /**
     * Clears the Dart channel only when [owner] still owns it — so an old
     * Activity's [android.app.Activity.onDestroy] cannot detach a newer one.
     */
    fun detachChannel(owner: Any) {
        if (channelOwner === owner) {
            channel = null
            channelOwner = null
        }
    }

    fun ensureRegistered(context: Context) {
        if (registered) {
            return
        }
        synchronized(this) {
            if (registered) {
                return
            }
            context.applicationContext.registerComponentCallbacks(this)
            registered = true
            log("registered ComponentCallbacks2")
        }
    }

    @VisibleForTesting
    fun unregisterForTest(context: Context) {
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
        channelOwner = null
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

        @Volatile
        private var instance: SevereMemoryPressureBridge? = null

        /**
         * Process-scoped instance. Registers Application callbacks once.
         * [log] is only used when creating the singleton (first call) and must
         * not capture an Activity (or any shorter-lived object).
         */
        @JvmStatic
        fun get(
            context: Context,
            log: ((String) -> Unit)? = null,
        ): SevereMemoryPressureBridge {
            val existing = instance
            if (existing != null) {
                existing.ensureRegistered(context)
                return existing
            }
            return synchronized(this) {
                instance?.also { it.ensureRegistered(context) }
                    ?: SevereMemoryPressureBridge(
                        log = log ?: { message ->
                            Log.d(TAG, message)
                            Unit
                        },
                    ).also { created ->
                        instance = created
                        created.ensureRegistered(context)
                    }
            }
        }

        @VisibleForTesting
        @JvmStatic
        fun resetForTest() {
            synchronized(this) {
                instance = null
            }
        }

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


