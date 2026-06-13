package com.tilawa.app

import android.app.Activity
import android.app.Application
import android.util.Log

/**
 * Notifies Dart when Credential Manager [HiddenActivity] is torn down on
 * Transsion ROMs (back press or system dismiss) so hung [authenticate] futures
 * can be aborted without waiting for the provider timeout.
 */
object TranssionCredentialUiLifecycle {
    private const val TAG = "TilawaGSignIn"
    private const val HIDDEN_ACTIVITY_SUFFIX = "HiddenActivity"

    @Volatile
    private var registered = false

    fun ensureRegistered(application: Application) {
        if (!TranssionOemPolicy.isTranssionDevice() || registered) {
            return
        }
        synchronized(this) {
            if (registered) {
                return
            }
            registered = true
            application.registerActivityLifecycleCallbacks(
                object : Application.ActivityLifecycleCallbacks {
                    override fun onActivityCreated(
                        activity: Activity,
                        savedInstanceState: android.os.Bundle?,
                    ) = Unit

                    override fun onActivityStarted(activity: Activity) = Unit

                    override fun onActivityResumed(activity: Activity) = Unit

                    override fun onActivityPaused(activity: Activity) = Unit

                    override fun onActivityStopped(activity: Activity) {
                        if (!activity.javaClass.name.endsWith(HIDDEN_ACTIVITY_SUFFIX)) {
                            return
                        }
                        Log.d(TAG, "H6 HiddenActivity stopped")
                        MainActivity.invokeCredentialUiDismissed?.invoke()
                    }

                    override fun onActivitySaveInstanceState(
                        activity: Activity,
                        outState: android.os.Bundle,
                    ) = Unit

                    override fun onActivityDestroyed(activity: Activity) {
                        if (!activity.javaClass.name.endsWith(HIDDEN_ACTIVITY_SUFFIX)) {
                            return
                        }
                        Log.d(TAG, "H6 HiddenActivity destroyed")
                        MainActivity.invokeCredentialUiDismissed?.invoke()
                    }
                },
            )
        }
    }
}
