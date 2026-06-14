package de.ffuf.in_app_update

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.IntentSender.SendIntentException
import com.google.android.gms.tasks.Tasks
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallState
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallErrorCode
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentCaptor
import org.mockito.ArgumentMatchers.anyInt
import org.mockito.Mock
import org.mockito.Mockito.atLeastOnce
import org.mockito.Mockito.doAnswer
import org.mockito.Mockito.doThrow
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.any
import org.mockito.kotlin.whenever
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], manifest = Config.NONE)
class InAppUpdatePluginTest {

    private lateinit var plugin: InAppUpdatePlugin

    @Mock
    private lateinit var mockResult: MethodChannel.Result

    @Mock
    private lateinit var mockEventSink: EventChannel.EventSink

    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        plugin = InAppUpdatePlugin()
    }

    private fun createActivity(): Activity {
        return Robolectric.buildActivity(Activity::class.java).create().start().resume().get()
    }

    private fun attachActivity(activity: Activity) {
        plugin.setActivityProviderForTesting(object : ActivityProvider {
            override fun addActivityResultListener(
                callback: PluginRegistry.ActivityResultListener,
            ) = Unit

            override fun activity(): Activity = activity
        })
    }

    private fun dispatchAsyncTasks() {
        ShadowLooper.idleMainLooper()
    }

    private fun callMethod(method: String) {
        plugin.onMethodCall(MethodCall(method, null), mockResult)
        dispatchAsyncTasks()
    }

    private fun attachPluginEngine() {
        val messenger = mock(BinaryMessenger::class.java)
        val binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        whenever(binding.binaryMessenger).thenReturn(messenger)
        plugin.onAttachedToEngine(binding)
    }

    private fun mockUpdateInfo(
        updateAvailability: Int = UpdateAvailability.UPDATE_AVAILABLE,
        immediateAllowed: Boolean = true,
        flexibleAllowed: Boolean = true,
        installStatus: Int = InstallStatus.UNKNOWN,
    ): AppUpdateInfo {
        val info = mock(AppUpdateInfo::class.java)
        whenever(info.updateAvailability()).thenReturn(updateAvailability)
        whenever(info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)).thenReturn(immediateAllowed)
        whenever(info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)).thenReturn(flexibleAllowed)
        whenever(info.getFailedUpdatePreconditions(any())).thenReturn(emptySet())
        whenever(info.availableVersionCode()).thenReturn(88)
        whenever(info.installStatus()).thenReturn(installStatus)
        whenever(info.packageName()).thenReturn("de.test.app")
        whenever(info.clientVersionStalenessDays()).thenReturn(3)
        whenever(info.updatePriority()).thenReturn(4)
        whenever(info.totalBytesToDownload()).thenReturn(1_000_000L)
        whenever(info.bytesDownloaded()).thenReturn(500_000L)
        return info
    }

    private fun mockManager(info: AppUpdateInfo): AppUpdateManager {
        val manager = mock(AppUpdateManager::class.java)
        whenever(manager.appUpdateInfo).thenReturn(Tasks.forResult(info))
        return manager
    }

    private fun immediateUpdateOptions(): AppUpdateOptions =
        AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build()

    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        plugin.onMethodCall(MethodCall("unknown", null), mockResult)

        verify(mockResult).notImplemented()
    }

    @Test
    fun checkForUpdate_withoutActivity_returnsRequireForegroundActivity() {
        plugin.onMethodCall(MethodCall("checkForUpdate", null), mockResult)

        verify(mockResult).error(
            "REQUIRE_FOREGROUND_ACTIVITY",
            "in_app_update requires a foreground activity",
            null,
        )
    }

    @Test
    fun checkForUpdate_success_returnsPlayFields() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo()
        val manager = mockManager(info)
        plugin.appUpdateManagerFactory = { manager }

        callMethod("checkForUpdate")

        verify(manager).registerListener(any())
        val captor = ArgumentCaptor.forClass(Map::class.java)
        verify(mockResult).success(captor.capture())
        @Suppress("UNCHECKED_CAST")
        val payload = captor.value as Map<String, Any?>
        assertEquals(UpdateAvailability.UPDATE_AVAILABLE, payload["updateAvailability"])
        assertEquals(true, payload["immediateAllowed"])
        assertEquals(true, payload["flexibleAllowed"])
        assertEquals(88, payload["availableVersionCode"])
        assertEquals("de.test.app", payload["packageName"])
        assertEquals(3, payload["clientVersionStalenessDays"])
        assertEquals(4, payload["updatePriority"])
        assertEquals(1_000_000L, payload["totalBytesToDownload"])
        assertEquals(500_000L, payload["bytesDownloaded"])
    }

    @Test
    fun checkForUpdate_taskFailure_returnsTaskFailure() {
        val activity = createActivity()
        attachActivity(activity)
        val manager = mock(AppUpdateManager::class.java)
        whenever(manager.appUpdateInfo).thenReturn(
            Tasks.forException(RuntimeException("network")),
        )
        plugin.appUpdateManagerFactory = { manager }

        callMethod("checkForUpdate")

        verify(mockResult).error("TASK_FAILURE", "network", null)
    }

    @Test
    fun performImmediateUpdate_withoutActivity_returnsRequireForegroundActivity() {
        callMethod("performImmediateUpdate")

        verify(mockResult).error(
            "REQUIRE_FOREGROUND_ACTIVITY",
            "in_app_update requires a foreground activity",
            null,
        )
    }

    @Test
    fun performImmediateUpdate_whenNotAllowed_returnsInAppUpdateFailed() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo(immediateAllowed = false)
        plugin.setAppUpdateManagerForTesting(mockManager(info))

        callMethod("performImmediateUpdate")

        verify(mockResult).error(
            "IN_APP_UPDATE_FAILED",
            "Immediate update is not allowed for the current AppUpdateInfo.",
            null,
        )
    }

    @Test
    fun performImmediateUpdate_whenAllowed_startsUpdateFlow() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo()
        val manager = mockManager(info)
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("performImmediateUpdate")

        verify(manager).startUpdateFlowForResult(
            info,
            activity,
            immediateUpdateOptions(),
            1276,
        )
    }

    @Test
    fun performImmediateUpdate_sendIntentException_returnsInAppUpdateFailed() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo()
        val manager = mockManager(info)
        doThrow(SendIntentException("boom")).whenever(manager).startUpdateFlowForResult(
            any<AppUpdateInfo>(),
            any<Activity>(),
            any<AppUpdateOptions>(),
            anyInt(),
        )
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("performImmediateUpdate")

        verify(mockResult).error("IN_APP_UPDATE_FAILED", "boom", null)
    }

    @Test
    fun performImmediateUpdate_taskFailure_returnsTaskFailure() {
        val activity = createActivity()
        attachActivity(activity)
        val manager = mock(AppUpdateManager::class.java)
        whenever(manager.appUpdateInfo).thenReturn(
            Tasks.forException(RuntimeException("task failed")),
        )
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("performImmediateUpdate")

        verify(mockResult).error("TASK_FAILURE", "task failed", null)
    }

    @Test
    fun startFlexibleUpdate_whenNotAllowed_returnsInAppUpdateFailed() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo(flexibleAllowed = false)
        plugin.setAppUpdateManagerForTesting(mockManager(info))

        callMethod("startFlexibleUpdate")

        verify(mockResult).error(
            "IN_APP_UPDATE_FAILED",
            "Flexible update is not allowed for the current AppUpdateInfo.",
            null,
        )
    }

    @Test
    fun startFlexibleUpdate_downloadCompleted_returnsSuccess() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo()
        val manager = mockManager(info)
        val listenerCaptor = ArgumentCaptor.forClass(InstallStateUpdatedListener::class.java)
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("startFlexibleUpdate")
        verify(manager, atLeastOnce()).registerListener(listenerCaptor.capture())

        val installListener = listenerCaptor.allValues.first()
        val state = mock(InstallState::class.java)
        whenever(state.installStatus()).thenReturn(InstallStatus.DOWNLOADED)
        installListener.onStateUpdate(state)

        verify(mockResult).success(null)
    }

    @Test
    fun startFlexibleUpdate_installError_returnsError() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo()
        val manager = mockManager(info)
        val listenerCaptor = ArgumentCaptor.forClass(InstallStateUpdatedListener::class.java)
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("startFlexibleUpdate")
        verify(manager, atLeastOnce()).registerListener(listenerCaptor.capture())

        val installListener = listenerCaptor.allValues.first()
        val state = mock(InstallState::class.java)
        whenever(state.installStatus()).thenReturn(InstallStatus.FAILED)
        whenever(state.installErrorCode()).thenReturn(InstallErrorCode.ERROR_INTERNAL_ERROR)
        installListener.onStateUpdate(state)

        verify(mockResult).error(
            "Error during installation",
            InstallErrorCode.ERROR_INTERNAL_ERROR.toString(),
            null,
        )
    }

    @Test
    fun completeFlexibleUpdate_whenNotDownloaded_returnsInAppUpdateFailed() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo(installStatus = InstallStatus.DOWNLOADING)
        val manager = mockManager(info)
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("completeFlexibleUpdate")

        verify(mockResult).error(
            "IN_APP_UPDATE_FAILED",
            "Flexible update is not downloaded yet.",
            null,
        )
        verify(manager, never()).completeUpdate()
    }

    @Test
    fun completeFlexibleUpdate_whenDownloaded_completesUpdate() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo(installStatus = InstallStatus.DOWNLOADED)
        val manager = mockManager(info)
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("completeFlexibleUpdate")

        verify(manager).completeUpdate()
        verify(mockResult).success(null)
    }

    @Test
    fun openAppStoreListing_withoutActivity_returnsRequireForegroundActivity() {
        callMethod("openAppStoreListing")

        verify(mockResult).error(
            "REQUIRE_FOREGROUND_ACTIVITY",
            "in_app_update requires a foreground activity",
            null,
        )
    }

    @Test
    fun openAppStoreListing_marketIntentSucceeds_returnsSuccess() {
        val activity = createActivity()
        attachActivity(activity)

        callMethod("openAppStoreListing")

        verify(mockResult).success(null)
    }

    @Test
    fun openAppStoreListing_marketFails_webFallbackSucceeds() {
        val activity = Robolectric.buildActivity(MarketFailingActivity::class.java)
            .create()
            .start()
            .resume()
            .get()
        attachActivity(activity)

        callMethod("openAppStoreListing")

        verify(mockResult).success(null)
    }

    @Test
    fun openAppStoreListing_marketAndWebFail_returnsOpenStoreFailed() {
        val activity = Robolectric.buildActivity(FailingActivity::class.java)
            .create()
            .start()
            .resume()
            .get()
        attachActivity(activity)

        callMethod("openAppStoreListing")

        verify(mockResult).error(
            "OPEN_STORE_FAILED",
            "No handler",
            null,
        )
    }

    @Test
    fun onActivityResult_immediateCanceled_returnsUserDeniedUpdate() {
        plugin.setAppUpdateTypeForTesting(AppUpdateType.IMMEDIATE)
        plugin.setUpdateResultForTesting(mockResult)

        val handled = plugin.onActivityResult(1276, Activity.RESULT_CANCELED, null)

        assertTrue(handled)
        verify(mockResult).error("USER_DENIED_UPDATE", Activity.RESULT_CANCELED.toString(), null)
    }

    @Test
    fun onActivityResult_immediateOk_returnsSuccess() {
        plugin.setAppUpdateTypeForTesting(AppUpdateType.IMMEDIATE)
        plugin.setUpdateResultForTesting(mockResult)

        val handled = plugin.onActivityResult(1276, Activity.RESULT_OK, null)

        assertTrue(handled)
        verify(mockResult).success(null)
    }

    @Test
    fun onActivityResult_immediateFailed_returnsInAppUpdateFailed() {
        plugin.setAppUpdateTypeForTesting(AppUpdateType.IMMEDIATE)
        plugin.setUpdateResultForTesting(mockResult)

        val handled = plugin.onActivityResult(
            1276,
            com.google.android.play.core.install.model.ActivityResult.RESULT_IN_APP_UPDATE_FAILED,
            null,
        )

        assertTrue(handled)
        verify(mockResult).error(
            "IN_APP_UPDATE_FAILED",
            "Some other error prevented either the user from providing consent or the update to proceed.",
            null,
        )
    }

    @Test
    fun onActivityResult_flexibleCanceled_returnsUserDeniedUpdate() {
        plugin.setAppUpdateTypeForTesting(AppUpdateType.FLEXIBLE)
        plugin.setUpdateResultForTesting(mockResult)

        val handled = plugin.onActivityResult(1276, Activity.RESULT_CANCELED, null)

        assertTrue(handled)
        verify(mockResult).error("USER_DENIED_UPDATE", Activity.RESULT_CANCELED.toString(), null)
    }

    @Test
    fun onActivityResult_unknownRequestCode_returnsFalse() {
        val handled = plugin.onActivityResult(999, Activity.RESULT_OK, null)

        assertFalse(handled)
        verify(mockResult, never()).success(any())
    }

    @Test
    fun onListen_andOnCancel_manageEventSink() {
        plugin.onListen(null, mockEventSink)
        plugin.onCancel(null)
    }

    @Test
    fun onAttachedToEngine_registersInstallListenerWhenManagerExists() {
        val manager = mock(AppUpdateManager::class.java)
        plugin.setAppUpdateManagerForTesting(manager)
        attachPluginEngine()

        verify(manager, atLeastOnce()).registerListener(any())
    }

    @Test
    fun onDetachedFromEngine_unregistersInstallListener() {
        val manager = mock(AppUpdateManager::class.java)
        plugin.setAppUpdateManagerForTesting(manager)
        val messenger = mock(BinaryMessenger::class.java)
        val binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        whenever(binding.binaryMessenger).thenReturn(messenger)
        plugin.onAttachedToEngine(binding)
        plugin.onDetachedFromEngine(binding)

        verify(manager).unregisterListener(any())
    }

    @Test
    fun onActivityResumed_resumesStalledImmediateUpdate() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo(
            updateAvailability = UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS,
        )
        val manager = mockManager(info)
        plugin.setAppUpdateManagerForTesting(manager)

        plugin.onActivityResumed(activity)
        dispatchAsyncTasks()

        verify(manager).startUpdateFlowForResult(
            info,
            activity,
            immediateUpdateOptions(),
            1276,
        )
    }

    @Test
    fun onActivityResumed_notifiesDownloadedFlexibleUpdate() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo(installStatus = InstallStatus.DOWNLOADED)
        val manager = mockManager(info)
        plugin.setAppUpdateManagerForTesting(manager)
        plugin.onListen(null, mockEventSink)

        plugin.onActivityResumed(activity)
        dispatchAsyncTasks()

        verify(mockEventSink).success(InstallStatus.DOWNLOADED)
    }

    @Test
    fun activityAwareCallbacks_attachAndDetachProvider() {
        val binding = mock(ActivityPluginBinding::class.java)
        val activity = createActivity()
        whenever(binding.activity).thenReturn(activity)
        doAnswer { invocation ->
            val listener = invocation.arguments[0] as PluginRegistry.ActivityResultListener
            listener.onActivityResult(1276, Activity.RESULT_OK, null)
            null
        }.whenever(binding).addActivityResultListener(any())

        plugin.onAttachedToActivity(binding)
        assertNotNull(plugin)
        plugin.onDetachedFromActivityForConfigChanges()
        plugin.onReattachedToActivityForConfigChanges(binding)
        plugin.onDetachedFromActivity()
    }

    @Test
    fun activityLifecycleCallbacks_areNoOpsExceptResume() {
        val activity = createActivity()

        plugin.onActivityCreated(activity, null)
        plugin.onActivityStarted(activity)
        plugin.onActivityPaused(activity)
        plugin.onActivityStopped(activity)
        plugin.onActivitySaveInstanceState(activity, mock(android.os.Bundle::class.java))
        plugin.onActivityDestroyed(activity)
        plugin.onActivityResumed(activity)
        dispatchAsyncTasks()
    }

    @Test
    fun requireAppUpdateManager_registersGlobalListenerOnce() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo()
        val manager = mockManager(info)
        plugin.appUpdateManagerFactory = { manager }

        callMethod("checkForUpdate")
        callMethod("performImmediateUpdate")

        verify(manager, atLeastOnce()).registerListener(any())
    }

    @Test
    fun eventListener_forwardsInstallStatusToSink() {
        val manager = mock(AppUpdateManager::class.java)
        plugin.setAppUpdateManagerForTesting(manager)
        attachPluginEngine()
        plugin.onListen(null, mockEventSink)

        val listenerCaptor = ArgumentCaptor.forClass(InstallStateUpdatedListener::class.java)
        verify(manager).registerListener(listenerCaptor.capture())

        val state = mock(InstallState::class.java)
        whenever(state.installStatus()).thenReturn(InstallStatus.DOWNLOADING)
        listenerCaptor.value.onStateUpdate(state)

        verify(mockEventSink).success(InstallStatus.DOWNLOADING)
    }

    @Test
    fun onActivityResult_flexibleFailed_returnsInAppUpdateFailed() {
        plugin.setAppUpdateTypeForTesting(AppUpdateType.FLEXIBLE)
        plugin.setUpdateResultForTesting(mockResult)

        val handled = plugin.onActivityResult(
            1276,
            com.google.android.play.core.install.model.ActivityResult.RESULT_IN_APP_UPDATE_FAILED,
            null,
        )

        assertTrue(handled)
        verify(mockResult).error(
            "IN_APP_UPDATE_FAILED",
            com.google.android.play.core.install.model.ActivityResult.RESULT_IN_APP_UPDATE_FAILED.toString(),
            null,
        )
    }

    @Test
    fun completeFlexibleUpdate_taskFailure_returnsTaskFailure() {
        val activity = createActivity()
        attachActivity(activity)
        val manager = mock(AppUpdateManager::class.java)
        whenever(manager.appUpdateInfo).thenReturn(
            Tasks.forException(RuntimeException("complete failed")),
        )
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("completeFlexibleUpdate")

        verify(mockResult).error("TASK_FAILURE", "complete failed", null)
    }

    @Test
    fun startFlexibleUpdate_sendIntentException_returnsInAppUpdateFailed() {
        val activity = createActivity()
        attachActivity(activity)
        val info = mockUpdateInfo()
        val manager = mockManager(info)
        doThrow(SendIntentException("flex fail")).whenever(manager).startUpdateFlowForResult(
            any<AppUpdateInfo>(),
            any<Activity>(),
            any<AppUpdateOptions>(),
            anyInt(),
        )
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("startFlexibleUpdate")

        verify(mockResult).error("IN_APP_UPDATE_FAILED", "flex fail", null)
    }

    @Test
    fun startFlexibleUpdate_taskFailure_returnsTaskFailure() {
        val activity = createActivity()
        attachActivity(activity)
        val manager = mock(AppUpdateManager::class.java)
        whenever(manager.appUpdateInfo).thenReturn(
            Tasks.forException(RuntimeException("flex task failed")),
        )
        plugin.setAppUpdateManagerForTesting(manager)

        callMethod("startFlexibleUpdate")

        verify(mockResult).error("TASK_FAILURE", "flex task failed", null)
    }
}

class MarketFailingActivity : Activity() {
    override fun startActivity(intent: Intent) {
        if (intent.data?.scheme == "market") {
            throw ActivityNotFoundException("Play Store missing")
        }
        super.startActivity(intent)
    }
}

class FailingActivity : Activity() {
    override fun startActivity(intent: Intent) {
        throw ActivityNotFoundException("No handler")
    }
}
