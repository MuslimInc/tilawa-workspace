package com.tilawa.app.widget.ayah

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.tilawa.app.MainActivity
import com.tilawa.app.R
import com.tilawa.app.widget.WidgetSnapshotStore
import com.tilawa.app.widget.WidgetType
import java.io.File

/**
 * Ayah of the Day home-screen widget (spec 041, User Story 2).
 *
 * Displays a verse pre-rendered in authentic QCF Mushaf script. The Flutter
 * repository renders light/dark PNG artifacts at snapshot time, so this
 * provider only decodes a bounded bitmap — no Dart isolate, fully offline,
 * reboot-safe (FR-004/FR-005/FR-010).
 *
 * Refresh strategy: one inexact allow-while-idle alarm at the snapshot's
 * `validUntilMs` (local midnight) flips to the stale cue until the app's next
 * launch publishes the new day. Data refreshes arrive via the
 * [ACTION_REFRESH] broadcast sent by the method channel after each publish.
 */
internal class AyahOfDayWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        renderAll(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            renderAll(context, manager, widgetIds(context, manager))
        }
    }

    override fun onDisabled(context: Context) {
        cancelMidnightAlarm(context)
        super.onDisabled(context)
    }

    private fun renderAll(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        if (appWidgetIds.isEmpty()) return
        val envelope = WidgetSnapshotStore(context).read(WidgetType.AYAH)
        val payload = envelope?.payload?.let(AyahWidgetPayload::parse)
        val nowMs = System.currentTimeMillis()
        val isStale = envelope?.validUntilMs?.let { nowMs >= it } ?: false
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(
                id,
                buildViews(context, payload, isStale),
            )
        }
        scheduleMidnightAlarm(context, envelope?.validUntilMs, nowMs)
    }

    private fun buildViews(
        context: Context,
        payload: AyahWidgetPayload?,
        isStale: Boolean,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_ayah_of_day)
        views.setOnClickPendingIntent(
            R.id.ayah_widget_root,
            openMushafIntent(context, payload?.pageNumber),
        )

        val bitmap = payload?.let { decodeArtwork(context, it) }
        if (payload == null || bitmap == null) {
            views.setViewVisibility(R.id.ayah_widget_image, View.GONE)
            views.setViewVisibility(R.id.ayah_widget_caption, View.GONE)
            views.setViewVisibility(R.id.ayah_widget_empty, View.VISIBLE)
            return views
        }

        views.setViewVisibility(R.id.ayah_widget_image, View.VISIBLE)
        views.setViewVisibility(R.id.ayah_widget_caption, View.VISIBLE)
        views.setViewVisibility(R.id.ayah_widget_empty, View.GONE)
        views.setImageViewBitmap(R.id.ayah_widget_image, bitmap)
        views.setTextViewText(
            R.id.ayah_widget_caption,
            if (isStale) {
                // Keep last-known verse visible with a refresh cue (FR-014).
                "${payload.caption} · ${context.getString(R.string.widget_stale_hint)}"
            } else {
                payload.caption
            },
        )
        return views
    }

    /** Decodes the artifact with [BitmapFactory.Options.inSampleSize] so large
     *  PNGs cannot spike widget-process RAM (Play Console bitmap-downsample
     *  guidance). The widget background is the brand-green gradient in BOTH
     *  themes, so the white-glyph (dark) artifact is always the readable one;
     *  the light artifact is kept for a future light-surface variant. */
    private fun decodeArtwork(context: Context, payload: AyahWidgetPayload): Bitmap? {
        val path = payload.imagePathDark
        return try {
            val file = File(path)
            if (!file.exists()) return null
            val maxPx = context.resources.displayMetrics.widthPixels
                .coerceIn(MIN_DECODE_PX, MAX_DECODE_PX)
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.absolutePath, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
            val options = BitmapFactory.Options().apply {
                inSampleSize = calculateInSampleSize(bounds, maxPx, maxPx)
            }
            BitmapFactory.decodeFile(file.absolutePath, options)
        } catch (t: Throwable) {
            Log.w(TAG, "Ayah artifact decode failed", t)
            null
        }
    }

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int,
    ): Int {
        val (height, width) = options.outHeight to options.outWidth
        var inSampleSize = 1
        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2
            while (halfHeight / inSampleSize >= reqHeight &&
                halfWidth / inSampleSize >= reqWidth
            ) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }

    private fun openMushafIntent(context: Context, pageNumber: Int?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_MUSHAF_PAGE
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            if (pageNumber != null) putExtra(EXTRA_PAGE_NUMBER, pageNumber)
        }
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN_MUSHAF,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun scheduleMidnightAlarm(context: Context, validUntilMs: Long?, nowMs: Long) {
        if (validUntilMs == null || validUntilMs <= nowMs) {
            cancelMidnightAlarm(context)
            return
        }
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        try {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC,
                validUntilMs + BOUNDARY_GRACE_MS,
                refreshPendingIntent(context),
            )
        } catch (e: SecurityException) {
            Log.w(TAG, "Midnight alarm rejected", e)
        }
    }

    private fun cancelMidnightAlarm(context: Context) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(refreshPendingIntent(context))
    }

    private fun refreshPendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            REQUEST_REFRESH,
            Intent(context, AyahOfDayWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    companion object {
        private const val TAG = "AyahWidget"

        /** Must match the broadcast built in MethodChannelLogic:
         *  "com.tilawa.app.widget.<WIRE_NAME_UPPERCASE>.ACTION_REFRESH". */
        const val ACTION_REFRESH = "com.tilawa.app.widget.AYAH.ACTION_REFRESH"
        const val ACTION_OPEN_MUSHAF_PAGE =
            "com.tilawa.app.widget.ayah.ACTION_OPEN_MUSHAF_PAGE"
        const val EXTRA_PAGE_NUMBER = "page_number"
        private const val REQUEST_REFRESH = 0x41595247 // 'AYRG'
        private const val REQUEST_OPEN_MUSHAF = 0x41594F4D // 'AYOM'
        private const val BOUNDARY_GRACE_MS = 2_000L
        private const val MIN_DECODE_PX = 480
        private const val MAX_DECODE_PX = 1080

        private fun widgetIds(context: Context, manager: AppWidgetManager): IntArray =
            manager.getAppWidgetIds(
                ComponentName(context, AyahOfDayWidgetProvider::class.java),
            )
    }
}
