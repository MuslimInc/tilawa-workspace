package de.ffuf.in_app_update

import android.app.Activity
import android.app.Activity.RESULT_CANCELED
import android.app.Activity.RESULT_OK
import android.app.Application
import android.content.Intent
import android.content.IntentSender.SendIntentException
import android.os.Bundle
import android.util.Log
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallState
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

interface ActivityProvider {
    fun addActivityResultListener(callback: PluginRegistry.ActivityResultListener)
    fun activity(): Activity
}

class InAppUpdatePlugin : FlutterPlugin, MethodCallHandler,
    PluginRegistry.ActivityResultListener, Application.ActivityLifecycleCallbacks, ActivityAware,
    EventChannel.StreamHandler {

    companion object {
        private const val TAG = "in_app_update"
        private const val REQUEST_CODE_START_UPDATE = 1276
    }

    internal var appUpdateManagerFactory: (Activity) -> AppUpdateManager = { activity ->
        AppUpdateManagerFactory.create(activity)
    }

    internal fun setActivityProviderForTesting(provider: ActivityProvider?) {
        activityProvider = provider
    }

    internal fun setAppUpdateManagerForTesting(manager: AppUpdateManager?) {
        appUpdateManager = manager
    }

    internal fun setAppUpdateTypeForTesting(type: Int?) {
        appUpdateType = type
    }

    internal fun setUpdateResultForTesting(result: Result?) {
        updateResult = result
    }

    private lateinit var channel: MethodChannel
    private lateinit var event: EventChannel
    private val installStateUpdatedListener = InstallStateUpdatedListener { state ->
        onInstallStateUpdated(state)
    }
    private var installStateSink: EventChannel.EventSink? = null
    private var globalListenerRegistered = false

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        installStateSink = events
    }

    override fun onCancel(arguments: Any?) {
        installStateSink = null
    }

    private fun publishInstallStatusCode(installStatus: Int) {
        installStateSink?.success(installStatus)
    }

    private fun onInstallStateUpdated(state: InstallState) {
        publishInstallStatusCode(state.installStatus())
        handleFlexibleInstallState(state)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "de.ffuf.in_app_update/methods")
        channel.setMethodCallHandler(this)

        event = EventChannel(flutterPluginBinding.binaryMessenger,"de.ffuf.in_app_update/stateEvents" )
        event.setStreamHandler(this)

        appUpdateManager?.let { ensureGlobalListenerRegistered(it) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        event.setStreamHandler(null)
        unregisterGlobalListener()
        unregisterLifecycleCallbacksIfNeeded()
    }

    private var activityProvider: ActivityProvider? = null

    private var updateResult: Result? = null
    private var appUpdateType: Int? = null
    private var appUpdateInfo: AppUpdateInfo? = null
    private var appUpdateManager: AppUpdateManager? = null
    private var lifecycleApplication: Application? = null

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkForUpdate" -> checkForUpdate(result)
            "performImmediateUpdate" -> performImmediateUpdate(result)
            "startFlexibleUpdate" -> startFlexibleUpdate(result)
            "completeFlexibleUpdate" -> completeFlexibleUpdate(result)
            "openAppStoreListing" -> openAppStoreListing(result)
            else -> result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_START_UPDATE) {
            if (appUpdateType == AppUpdateType.IMMEDIATE) {
                when (resultCode) {
                    RESULT_CANCELED -> {
                        updateResult?.error("USER_DENIED_UPDATE", resultCode.toString(), null)
                    }
                    RESULT_OK -> {
                        updateResult?.success(null)
                    }
                    ActivityResult.RESULT_IN_APP_UPDATE_FAILED -> {
                        updateResult?.error("IN_APP_UPDATE_FAILED", "Some other error prevented either the user from providing consent or the update to proceed.", null)
                    }
                }
                invalidateCachedUpdateInfo()
                updateResult = null
                return true
            } else if (appUpdateType == AppUpdateType.FLEXIBLE) {
                when (resultCode) {
                    RESULT_CANCELED -> {
                        updateResult?.error("USER_DENIED_UPDATE", resultCode.toString(), null)
                        updateResult = null
                        invalidateCachedUpdateInfo()
                    }
                    ActivityResult.RESULT_IN_APP_UPDATE_FAILED -> {
                        updateResult?.error("IN_APP_UPDATE_FAILED", resultCode.toString(), null)
                        updateResult = null
                        invalidateCachedUpdateInfo()
                    }
                }
                return true
            }
        }
        return false
    }


    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        activityProvider = object : ActivityProvider {
            override fun addActivityResultListener(callback: PluginRegistry.ActivityResultListener) {
                activityPluginBinding.addActivityResultListener(callback)
            }

            override fun activity(): Activity {
                return activityPluginBinding.activity
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityProvider = null
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        activityProvider = object : ActivityProvider {
            override fun addActivityResultListener(callback: PluginRegistry.ActivityResultListener) {
                activityPluginBinding.addActivityResultListener(callback)
            }

            override fun activity(): Activity {
                return activityPluginBinding.activity
            }
        }
    }

    override fun onDetachedFromActivity() {
        activityProvider = null
        unregisterLifecycleCallbacksIfNeeded()
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

    override fun onActivityPaused(activity: Activity) {}

    override fun onActivityStarted(activity: Activity) {}

    override fun onActivityDestroyed(activity: Activity) {}

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityStopped(activity: Activity) {}

    /// Play guidance: check stalled immediate updates and downloaded flexible
    /// updates whenever the app returns to the foreground.
    override fun onActivityResumed(activity: Activity) {
        val manager = appUpdateManager ?: return
        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                resumeImmediateUpdateIfNeeded(manager, activity, info)
                notifyDownloadedFlexibleUpdateIfNeeded(info)
            }
    }

    private fun resumeImmediateUpdateIfNeeded(
        manager: AppUpdateManager,
        activity: Activity,
        info: AppUpdateInfo,
    ) {
        if (activity.isFinishing || activity.isDestroyed) {
            return
        }
        if (info.updateAvailability()
            != UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
        ) {
            return
        }

        try {
            manager.startUpdateFlowForResult(
                info,
                activity,
                immediateUpdateOptions(),
                REQUEST_CODE_START_UPDATE,
            )
        } catch (e: SendIntentException) {
            Log.e(TAG, "Could not resume immediate update flow", e)
        }
    }

    private fun notifyDownloadedFlexibleUpdateIfNeeded(info: AppUpdateInfo) {
        if (info.installStatus() == InstallStatus.DOWNLOADED) {
            publishInstallStatusCode(InstallStatus.DOWNLOADED)
        }
    }

    private fun performImmediateUpdate(result: Result) {
        if (updateResult != null) {
            result.error(
                "UPDATE_IN_PROGRESS",
                "An update flow is already in progress.",
                null,
            )
            return
        }
        val manager = requireAppUpdateManager(result) ?: return
        val activity = requireActivity(result) ?: return

        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE
                    || !info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
                ) {
                    invalidateCachedUpdateInfo()
                    result.error(
                        "IN_APP_UPDATE_FAILED",
                        "Immediate update is not allowed for the current AppUpdateInfo.",
                        null,
                    )
                    return@addOnSuccessListener
                }

                appUpdateInfo = info
                appUpdateType = AppUpdateType.IMMEDIATE
                updateResult = result

                try {
                    manager.startUpdateFlowForResult(
                        info,
                        activity,
                        immediateUpdateOptions(),
                        REQUEST_CODE_START_UPDATE,
                    )
                    invalidateCachedUpdateInfo()
                } catch (e: SendIntentException) {
                    invalidateCachedUpdateInfo()
                    result.error("IN_APP_UPDATE_FAILED", e.message, null)
                }
            }
            .addOnFailureListener {
                invalidateCachedUpdateInfo()
                result.error("TASK_FAILURE", it.message, null)
            }
    }

    private fun startFlexibleUpdate(result: Result) {
        if (updateResult != null) {
            result.error(
                "UPDATE_IN_PROGRESS",
                "An update flow is already in progress.",
                null,
            )
            return
        }
        val manager = requireAppUpdateManager(result) ?: return
        val activity = requireActivity(result) ?: return

        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE
                    || !info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                ) {
                    invalidateCachedUpdateInfo()
                    result.error(
                        "IN_APP_UPDATE_FAILED",
                        "Flexible update is not allowed for the current AppUpdateInfo.",
                        null,
                    )
                    return@addOnSuccessListener
                }

                appUpdateInfo = info
                appUpdateType = AppUpdateType.FLEXIBLE
                updateResult = result

                // Register before starting the flow, per Play Core guidance.
                ensureGlobalListenerRegistered(manager)

                try {
                    manager.startUpdateFlowForResult(
                        info,
                        activity,
                        flexibleUpdateOptions(),
                        REQUEST_CODE_START_UPDATE,
                    )
                    invalidateCachedUpdateInfo()
                } catch (e: SendIntentException) {
                    invalidateCachedUpdateInfo()
                    result.error("IN_APP_UPDATE_FAILED", e.message, null)
                }
            }
            .addOnFailureListener {
                invalidateCachedUpdateInfo()
                result.error("TASK_FAILURE", it.message, null)
            }
    }

    private fun completeFlexibleUpdate(result: Result) {
        val manager = requireAppUpdateManager(result) ?: return

        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                appUpdateInfo = info
                if (info.installStatus() != InstallStatus.DOWNLOADED) {
                    result.error(
                        "IN_APP_UPDATE_FAILED",
                        "Flexible update is not downloaded yet.",
                        null,
                    )
                    return@addOnSuccessListener
                }

                manager.completeUpdate()
                result.success(null)
            }
            .addOnFailureListener {
                invalidateCachedUpdateInfo()
                result.error("TASK_FAILURE", it.message, null)
            }
    }

    private fun openAppStoreListing(result: Result) {
        val activity = activityProvider?.activity()
        if (activity == null) {
            result.error(
                "REQUIRE_FOREGROUND_ACTIVITY",
                "in_app_update requires a foreground activity",
                null,
            )
            return
        }

        val packageName = activity.packageName
        val marketIntent = Intent(Intent.ACTION_VIEW).apply {
            data = android.net.Uri.parse("market://details?id=$packageName")
            setPackage("com.android.vending")
        }

        try {
            activity.startActivity(marketIntent)
            result.success(null)
        } catch (e: Exception) {
            val webIntent = Intent(Intent.ACTION_VIEW).apply {
                data = android.net.Uri.parse(
                    "https://play.google.com/store/apps/details?id=$packageName",
                )
            }
            try {
                activity.startActivity(webIntent)
                result.success(null)
            } catch (webError: Exception) {
                result.error(
                    "OPEN_STORE_FAILED",
                    webError.message,
                    null,
                )
            }
        }
    }

    private fun checkForUpdate(result: Result) {
        val activity = requireActivity(result) ?: return
        val manager = requireAppUpdateManager(result) ?: return

        activityProvider?.addActivityResultListener(this)
        registerLifecycleCallbacksIfNeeded(activity)

        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                appUpdateInfo = info
                result.success(
                    mapOf(
                        "updateAvailability" to info.updateAvailability(),
                        "immediateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                        "immediateAllowedPreconditions" to info.getFailedUpdatePreconditions(immediateUpdateOptions()).map { it.toInt() }.toList(),
                        "flexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                        "flexibleAllowedPreconditions" to info.getFailedUpdatePreconditions(flexibleUpdateOptions()).map { it.toInt() }.toList(),
                        "availableVersionCode" to info.availableVersionCode(),
                        "installStatus" to info.installStatus(),
                        "packageName" to info.packageName(),
                        "clientVersionStalenessDays" to info.clientVersionStalenessDays(),
                        "updatePriority" to info.updatePriority(),
                        "totalBytesToDownload" to info.totalBytesToDownload(),
                        "bytesDownloaded" to info.bytesDownloaded(),
                    )
                )
            }
            .addOnFailureListener {
                result.error("TASK_FAILURE", it.message, null)
            }
    }

    private fun handleFlexibleInstallState(state: InstallState) {
        if (appUpdateType != AppUpdateType.FLEXIBLE) {
            return
        }

        when {
            state.installStatus() == InstallStatus.DOWNLOADED -> {
                updateResult?.success(null)
                updateResult = null
            }
            state.installErrorCode() != InstallErrorCode.NO_ERROR -> {
                updateResult?.error(
                    "Error during installation",
                    state.installErrorCode().toString(),
                    null,
                )
                updateResult = null
                invalidateCachedUpdateInfo()
            }
        }
    }

    private fun invalidateCachedUpdateInfo() {
        appUpdateInfo = null
    }

    private fun immediateUpdateOptions(): AppUpdateOptions =
        AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build()

    private fun flexibleUpdateOptions(): AppUpdateOptions =
        AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build()

    private fun registerLifecycleCallbacksIfNeeded(activity: Activity) {
        if (lifecycleApplication != null) {
            return
        }
        val application = activity.application
        application.registerActivityLifecycleCallbacks(this)
        lifecycleApplication = application
    }

    private fun unregisterLifecycleCallbacksIfNeeded() {
        lifecycleApplication?.unregisterActivityLifecycleCallbacks(this)
        lifecycleApplication = null
    }

    private fun requireAppUpdateManager(result: Result): AppUpdateManager? {
        val activity = requireActivity(result) ?: return null
        if (appUpdateManager == null) {
            appUpdateManager = appUpdateManagerFactory(activity)
        }
        ensureGlobalListenerRegistered(appUpdateManager!!)
        return appUpdateManager
    }

    private fun ensureGlobalListenerRegistered(manager: AppUpdateManager) {
        if (!globalListenerRegistered) {
            manager.registerListener(installStateUpdatedListener)
            globalListenerRegistered = true
        }
    }

    private fun unregisterGlobalListener() {
        if (globalListenerRegistered) {
            appUpdateManager?.unregisterListener(installStateUpdatedListener)
            globalListenerRegistered = false
        }
    }

    private fun requireActivity(result: Result): Activity? {
        val activity = activityProvider?.activity()
        if (activity == null) {
            result.error(
                "REQUIRE_FOREGROUND_ACTIVITY",
                "in_app_update requires a foreground activity",
                null,
            )
            return null
        }
        return activity
    }
}
