package com.tilawa.app.auth

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object GoogleSignInPrepareChannel {
    const val CHANNEL_NAME = "com.tilawa.app/google_sign_in_prepare"

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepare" -> {
                    val clientId = call.argument<String>("google_client_id")
                    if (clientId.isNullOrBlank()) {
                        result.error("BAD_ARGS", "google_client_id is required", null)
                        return@setMethodCallHandler
                    }
                    GoogleSignInPrepareBridge.prepare(activity, clientId) { success ->
                        result.success(success)
                    }
                }
                "clear" -> {
                    GoogleSignInPrepareBridge.clear()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
