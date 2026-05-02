package com.tilawa.app.prayer

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

/**
 * QA-only logger that writes to a persistent file.
 * Used for verifying the native Adhan pipeline when the app is closed/swiped.
 */
object AdhanQALogger {
    private const val TAG = "AdhanQALogger"
    private const val LOG_FILE_NAME = "adhan_qa_logs.txt"
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US)

    /**
     * Set this to true via MethodChannel to enable logging in production-like builds
     * if the dart-define is present.
     */
    var isEnabled: Boolean = false

    fun logEvent(
        context: Context,
        eventName: String,
        source: String = "Native",
        alarmId: Int? = null,
        prayerName: String? = null,
        scheduledMs: Long? = null,
        triggerMs: Long? = null,
        deltaMs: Long? = null,
        latencyMs: Long? = null,
        sound: String? = null,
        details: String? = null
    ) {
        if (!isEnabled && !isDebug(context)) return

        val timestamp = dateFormat.format(Date())
        val logLine = buildString {
            append("[$timestamp] ")
            append("source=$source ")
            append("event=$eventName ")
            alarmId?.let { append("id=$it ") }
            prayerName?.let { append("prayer=$it ") }
            scheduledMs?.let { append("scheduled=${dateFormat.format(Date(it))} ") }
            triggerMs?.let { append("actual=${dateFormat.format(Date(it))} ") }
            deltaMs?.let { append("delta=${it}ms ") }
            latencyMs?.let { append("latency=${it}ms ") }
            sound?.let { append("sound=$it ") }
            details?.let { append("details=\"$it\" ") }
        }

        Log.d(TAG, logLine)

        try {
            val logFile = File(context.filesDir, LOG_FILE_NAME)
            FileWriter(logFile, true).use { writer ->
                writer.append(logLine).append("\n")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to write to QA log file", e)
        }
    }

    private fun isDebug(context: Context): Boolean {
        return (context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    fun clearLogs(context: Context) {
        try {
            val logFile = File(context.filesDir, LOG_FILE_NAME)
            if (logFile.exists()) {
                logFile.delete()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear QA logs", e)
        }
    }

    fun getLogs(context: Context): String {
        return try {
            val logFile = File(context.filesDir, LOG_FILE_NAME)
            if (logFile.exists()) {
                logFile.readText()
            } else {
                "No logs found."
            }
        } catch (e: Exception) {
            "Error reading logs: ${e.message}"
        }
    }
}
