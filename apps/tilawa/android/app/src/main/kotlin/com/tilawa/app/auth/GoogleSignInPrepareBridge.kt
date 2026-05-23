package com.tilawa.app.auth

import android.content.Context
import android.os.Build
import android.util.Base64
import androidx.annotation.VisibleForTesting
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.PrepareGetCredentialResponse
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import java.security.SecureRandom
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Warms Android Credential Manager for Sign in with Google before the login
 * screen is shown. Uses [CredentialManager.prepareGetCredential] on API 34+.
 */
object GoogleSignInPrepareBridge {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    @Volatile
    private var credentialManager: CredentialManager? = null

    @Volatile
    private var prepareResponse: PrepareGetCredentialResponse? = null

    @Volatile
    private var isPrepareRunning: Boolean = false

    fun prepare(context: Context, googleClientId: String, onComplete: (Boolean) -> Unit) {
        if (googleClientId.isBlank()) {
            onComplete(false)
            return
        }
        if (prepareResponse != null) {
            onComplete(true)
            return
        }
        if (isPrepareRunning) {
            onComplete(true)
            return
        }
        isPrepareRunning = true
        scope.launch {
            val success = runPrepare(context.applicationContext, googleClientId)
            isPrepareRunning = false
            onComplete(success)
        }
    }

    private suspend fun runPrepare(context: Context, googleClientId: String): Boolean {
        return withContext(Dispatchers.Main) {
            try {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    return@withContext true
                }
                val manager = credentialManager ?: CredentialManager.create(context).also {
                    credentialManager = it
                }
                val option = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(googleClientId)
                    .setNonce(generateNonce())
                    .build()
                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(option)
                    .build()
                prepareResponse = manager.prepareGetCredential(request)
                true
            } catch (_: Exception) {
                prepareResponse = null
                false
            }
        }
    }

    fun clear() {
        prepareResponse = null
        isPrepareRunning = false
    }

    private const val NONCE_BYTES = 24

    /**
     * Generates a cryptographically-random nonce for the Google ID token
     * request. A predictable nonce (e.g. epoch ms) defeats the replay
     * protection that Sign in with Google's nonce field is designed for.
     */
    @VisibleForTesting
    internal fun generateNonce(): String {
        val bytes = ByteArray(NONCE_BYTES)
        SecureRandom().nextBytes(bytes)
        return Base64.encodeToString(
            bytes,
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP,
        )
    }

    @VisibleForTesting
    internal fun resetForTesting() {
        credentialManager = null
        prepareResponse = null
        isPrepareRunning = false
    }

    @VisibleForTesting
    internal fun hasPreparedResponseForTesting(): Boolean = prepareResponse != null
}
