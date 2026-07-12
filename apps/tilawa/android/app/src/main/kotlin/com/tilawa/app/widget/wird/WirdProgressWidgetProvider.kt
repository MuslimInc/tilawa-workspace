package com.tilawa.app.widget.wird

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.tilawa.app.MainActivity
import com.tilawa.app.R
import com.tilawa.app.widget.WidgetSnapshotStore
import com.tilawa.app.widget.WidgetType

/** Renders the display-ready Daily Wird snapshot without plan calculations. */
internal class WirdProgressWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        renderAll(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        appWidgetManager.updateAppWidget(
            appWidgetId,
            buildViews(context, readPayload(context), isStale(context), newOptions),
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH || intent.action in lifecycleActions) {
            val manager = AppWidgetManager.getInstance(context)
            renderAll(context, manager, widgetIds(context, manager))
        }
    }

    private fun renderAll(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        if (widgetIds.isEmpty()) return
        val payload = readPayload(context)
        val stale = isStale(context)
        for (widgetId in widgetIds) {
            manager.updateAppWidget(
                widgetId,
                buildViews(
                    context,
                    payload,
                    stale,
                    manager.getAppWidgetOptions(widgetId),
                ),
            )
        }
    }

    private fun readPayload(context: Context): WirdProgressWidgetPayload? =
        WidgetSnapshotStore(context).read(WidgetType.WIRD)
            ?.payload
            ?.let(WirdProgressWidgetPayload::parse)

    private fun isStale(context: Context): Boolean {
        val validUntil = WidgetSnapshotStore(context).read(WidgetType.WIRD)?.validUntilMs
        return validUntil != null && System.currentTimeMillis() >= validUntil
    }

    private fun buildViews(
        context: Context,
        payload: WirdProgressWidgetPayload?,
        stale: Boolean,
        options: Bundle,
    ): RemoteViews {
        val expanded = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) >=
            EXPANDED_MIN_WIDTH_DP
        val layout = if (expanded) R.layout.widget_wird_expanded else R.layout.widget_wird_compact
        val views = RemoteViews(context.packageName, layout)
        views.setOnClickPendingIntent(R.id.wird_widget_root, openKhatmaIntent(context))

        if (payload == null) {
            views.setViewVisibility(R.id.wird_widget_content, View.GONE)
            views.setViewVisibility(R.id.wird_widget_setup, View.VISIBLE)
            views.setContentDescription(
                R.id.wird_widget_root,
                context.getString(R.string.widget_wird_setup_accessibility),
            )
            return views
        }

        views.setViewVisibility(R.id.wird_widget_content, View.VISIBLE)
        views.setViewVisibility(R.id.wird_widget_setup, View.GONE)
        views.setTextViewText(R.id.wird_widget_title, payload.localizedTitle)
        views.setTextViewText(R.id.wird_widget_subtitle, payload.localizedSubtitle)
        views.setTextViewText(
            R.id.wird_widget_stale,
            if (stale) context.getString(R.string.widget_stale_hint) else "",
        )
        views.setViewVisibility(R.id.wird_widget_stale, if (stale) View.VISIBLE else View.GONE)
        views.setProgressBar(
            R.id.wird_widget_progress,
            PROGRESS_MAX,
            (payload.progressValue * PROGRESS_MAX).toInt(),
            false,
        )
        views.setContentDescription(R.id.wird_widget_root, payload.accessibilityLabel)
        return views
    }

    private fun openKhatmaIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("tilawa:///widget/khatma")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN_KHATMA,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        const val ACTION_REFRESH = "com.tilawa.app.widget.WIRD.ACTION_REFRESH"
        private const val REQUEST_OPEN_KHATMA = 0x57495244 // 'WIRD'
        private const val EXPANDED_MIN_WIDTH_DP = 250
        private const val PROGRESS_MAX = 10_000

        private val lifecycleActions = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_LOCALE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
        )

        private fun widgetIds(context: Context, manager: AppWidgetManager): IntArray =
            manager.getAppWidgetIds(
                ComponentName(context, WirdProgressWidgetProvider::class.java),
            )
    }
}
