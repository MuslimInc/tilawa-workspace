package com.tilawa.app

import android.content.Intent
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Handle the splash screen transition.
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
    }

    override fun getRenderMode(): RenderMode {
        // A cold start from a notification can launch through the lockscreen/
        // notification shade path. With SurfaceView, Flutter delays the first
        // Android draw until the first Flutter frame, which can deadlock that
        // transition and leave a persistent black screen. TextureView avoids
        // the pre-draw gate for this activity.
        return RenderMode.texture
    }
}
