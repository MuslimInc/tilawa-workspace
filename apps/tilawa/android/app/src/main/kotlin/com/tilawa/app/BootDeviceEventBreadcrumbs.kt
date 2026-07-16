package com.tilawa.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.sentry.Breadcrumb
import io.sentry.Sentry
import io.sentry.SentryLevel

/**
 * Tags [ACTION_SHUTDOWN] and [Intent.ACTION_AIRPLANE_MODE_CHANGED] with
 * [during_boot] so startup ANRs can be separated from runtime device events.
 */
internal object BootDeviceEventBreadcrumbs {
    private const val TAG = "BootDeviceEvent"
    private const val CATEGORY = "boot.device.event"

    @Volatile
    var bootInProgress: Boolean = true
        private set

    private var receiverRegistered = false

    private val receiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action ?: return
                record(action)
            }
        }

    fun resetForLaunch() {
        bootInProgress = true
    }

    fun markBootComplete() {
        bootInProgress = false
    }

    fun register(context: Context) {
        if (receiverRegistered) {
            return
        }
        val filter =
            IntentFilter().apply {
                addAction(Intent.ACTION_SHUTDOWN)
                addAction(Intent.ACTION_AIRPLANE_MODE_CHANGED)
            }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.registerReceiver(
                context,
                receiver,
                filter,
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
        } else {
            @Suppress("DEPRECATION")
            context.registerReceiver(receiver, filter)
        }
        receiverRegistered = true
    }

    fun unregister(context: Context) {
        if (!receiverRegistered) {
            return
        }
        try {
            context.unregisterReceiver(receiver)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "Boot device event receiver already unregistered", e)
        }
        receiverRegistered = false
    }

    fun record(action: String) {
        val duringBoot = bootInProgress
        Log.d(TAG, "device.event action=$action during_boot=$duringBoot")
        Sentry.addBreadcrumb(
            Breadcrumb().apply {
                category = CATEGORY
                type = "system"
                level = SentryLevel.INFO
                message = action
                setData("action", action)
                setData("during_boot", duringBoot)
            },
        )
    }

    fun recordTrimMemory(trimLevel: Int) {
        val duringBoot = bootInProgress
        Log.d(TAG, "device.event action=TRIM_MEMORY level=$trimLevel during_boot=$duringBoot")
        Sentry.addBreadcrumb(
            Breadcrumb().apply {
                category = CATEGORY
                type = "system"
                level = SentryLevel.WARNING
                message = "Trim memory"
                setData("action", "TRIM_MEMORY")
                setData("trim_level", trimLevel)
                setData("during_boot", duringBoot)
            },
        )
    }

    fun recordLowMemory() {
        val duringBoot = bootInProgress
        Log.d(TAG, "device.event action=LOW_MEMORY during_boot=$duringBoot")
        Sentry.addBreadcrumb(
            Breadcrumb().apply {
                category = CATEGORY
                type = "system"
                level = SentryLevel.WARNING
                message = "Low memory"
                setData("action", "LOW_MEMORY")
                setData("during_boot", duringBoot)
            },
        )
    }
}

