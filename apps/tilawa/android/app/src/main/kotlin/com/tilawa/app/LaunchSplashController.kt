package com.tilawa.app

import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.splashscreen.SplashScreenViewProvider

/**
 * Native half of cold-start splash ownership (pairs with Dart
 * [LaunchFirstFrameGate]).
 *
 * Hardening goals for OEM races (FLUTTER-A4 class):
 * - Reset keep-on-screen at every Activity create.
 * - Cancel the failsafe when Flutter reports ready.
 * - Defer splash-view removal when the view is still 0×0 / detached instead of
 *   tearing it down during an invalid surface state.
 */
class LaunchSplashController(
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
    private val failsafeMs: Long = DEFAULT_FAILSAFE_MS,
    private val log: (String) -> Unit = { message ->
        Log.d(FIRST_FRAME_TAG, message)
    },
    private val onDismissed: () -> Unit = {},
) {
    @Volatile
    var keepOnScreen: Boolean = true
        private set

    private var failsafeScheduled: Boolean = false

    private val failsafeRunnable = Runnable {
        if (!keepOnScreen) {
            return@Runnable
        }
        log("FAILSAFE: forcing keepOnScreen=false (Flutter never sent ready)")
        dismiss(reason = "failsafe")
    }

    fun resetForCreate() {
        cancelFailsafe()
        keepOnScreen = true
        failsafeScheduled = false
        scheduleFailsafe()
        log("LaunchSplashController.resetForCreate keepOnScreen=true")
    }

    fun dismissFromFlutterReady() {
        dismiss(reason = "flutter_ready")
    }

    fun onDestroy() {
        cancelFailsafe()
    }

    /**
     * Called from [androidx.core.splashscreen.SplashScreen.setOnExitAnimationListener].
     * Removal is posted (and optionally deferred) so OEMs with a 0×0 Flutter
     * surface are less likely to abort during splash teardown.
     */
    fun onExitAnimation(provider: SplashScreenViewProvider) {
        attemptRemove(provider, attempt = 0)
    }

    private fun dismiss(reason: String) {
        cancelFailsafe()
        if (!keepOnScreen) {
            log("dismiss skipped (already dismissed) reason=$reason")
            return
        }
        keepOnScreen = false
        log("dismiss reason=$reason → keepOnScreen=false")
        runCatching(onDismissed).onFailure { error ->
            log("onDismissed failed reason=$reason error=$error")
        }
    }

    private fun scheduleFailsafe() {
        if (failsafeScheduled) {
            return
        }
        failsafeScheduled = true
        mainHandler.postDelayed(failsafeRunnable, failsafeMs)
        log("failsafe scheduled in ${failsafeMs}ms")
    }

    private fun cancelFailsafe() {
        mainHandler.removeCallbacks(failsafeRunnable)
        failsafeScheduled = false
    }

    private fun attemptRemove(provider: SplashScreenViewProvider, attempt: Int) {
        mainHandler.post {
            val view = provider.view
            try {
                if (!view.isAttachedToWindow) {
                    log("splash remove: view detached attempt=$attempt → remove()")
                    provider.remove()
                    return@post
                }
                val width = view.width
                val height = view.height
                if ((width <= 0 || height <= 0) && attempt < MAX_ZERO_SIZE_DEFER_ATTEMPTS) {
                    log(
                        "splash remove deferred (view ${width}x${height}) " +
                            "attempt=$attempt",
                    )
                    mainHandler.postDelayed(
                        { attemptRemove(provider, attempt + 1) },
                        ZERO_SIZE_DEFER_DELAY_MS,
                    )
                    return@post
                }
                log("splash exit → remove() attempt=$attempt size=${width}x${height}")
                provider.remove()
            } catch (error: Throwable) {
                log("splash remove failed attempt=$attempt error=$error")
                runCatching { provider.remove() }
            }
        }
    }

    companion object {
        const val DEFAULT_FAILSAFE_MS: Long = 6_000L
        private const val FIRST_FRAME_TAG = "FirstFrame"
        private const val MAX_ZERO_SIZE_DEFER_ATTEMPTS = 5
        private const val ZERO_SIZE_DEFER_DELAY_MS = 16L
    }
}
