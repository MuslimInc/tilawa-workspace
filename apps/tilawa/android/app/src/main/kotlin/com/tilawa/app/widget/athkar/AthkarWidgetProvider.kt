package com.tilawa.app.widget.athkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.tilawa.app.MainActivity
import com.tilawa.app.R
import com.tilawa.app.widget.WidgetSnapshotStore
import com.tilawa.app.widget.WidgetType

/**
 * Morning/Evening athkar home-screen widget (spec 041, User Story 3).
 *
 * Shows one dhikr at a time from the set matching the local clock window
 * (morning 04:00–14:59, evening 15:00–03:59), with per-instance tap-to-advance
 * progress persisted across launcher restarts. Progress resets when the
 * window occurrence changes (see [AthkarWidgetLogic]).
 *
 * One inexact allow-while-idle alarm at the next window boundary flips the
 * set without the app running; the OS `updatePeriodMillis` backstop covers
 * missed alarms.
 */
internal class AthkarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        renderAll(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH -> {
                val manager = AppWidgetManager.getInstance(context)
                renderAll(context, manager, widgetIds(context, manager))
            }
            ACTION_ADVANCE -> {
                val widgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    advance(context, widgetId)
                }
            }
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val store = AthkarProgressStore(context)
        for (id in appWidgetIds) store.clear(id)
        super.onDeleted(context, appWidgetIds)
    }

    override fun onDisabled(context: Context) {
        cancelBoundaryAlarm(context)
        super.onDisabled(context)
    }

    private fun advance(context: Context, appWidgetId: Int) {
        val payload = readPayload(context) ?: return
        val state = AthkarWidgetLogic.resolveState(System.currentTimeMillis())
        val set = setFor(payload, state.period)
        val store = AthkarProgressStore(context)
        val current = AthkarWidgetLogic.effectiveIndex(
            storedPeriodKey = store.readPeriodKey(appWidgetId),
            storedIndex = store.readIndex(appWidgetId),
            currentPeriodKey = state.periodKey,
            setSize = set.size,
        )
        // Advance up to set.size (== completion state); tapping the completed
        // card starts the set over for those repeating it.
        val next = if (current >= set.size) 0 else current + 1
        store.write(appWidgetId, state.periodKey, next)
        AppWidgetManager.getInstance(context).updateAppWidget(
            appWidgetId,
            buildViews(context, appWidgetId, payload, state),
        )
    }

    private fun renderAll(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        if (appWidgetIds.isEmpty()) return
        val payload = readPayload(context)
        val state = AthkarWidgetLogic.resolveState(System.currentTimeMillis())
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(
                id,
                buildViews(context, id, payload, state),
            )
        }
        scheduleBoundaryAlarm(context, state.nextTransitionMs)
    }

    private fun readPayload(context: Context): AthkarWidgetPayload? =
        WidgetSnapshotStore(context).read(WidgetType.ATHKAR)
            ?.payload
            ?.let(AthkarWidgetPayload::parse)

    private fun setFor(payload: AthkarWidgetPayload, period: AthkarPeriod) =
        if (period == AthkarPeriod.MORNING) payload.morning else payload.evening

    private fun buildViews(
        context: Context,
        appWidgetId: Int,
        payload: AthkarWidgetPayload?,
        state: AthkarPeriodState,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_athkar)
        views.setOnClickPendingIntent(
            R.id.athkar_widget_root,
            openAthkarIntent(context, state.period),
        )

        if (payload == null) {
            views.setViewVisibility(R.id.athkar_widget_content, View.GONE)
            views.setViewVisibility(R.id.athkar_widget_empty, View.VISIBLE)
            return views
        }
        views.setViewVisibility(R.id.athkar_widget_content, View.VISIBLE)
        views.setViewVisibility(R.id.athkar_widget_empty, View.GONE)

        val set = setFor(payload, state.period)
        val title = if (state.period == AthkarPeriod.MORNING) {
            payload.morningTitle
        } else {
            payload.eveningTitle
        }
        val store = AthkarProgressStore(context)
        val index = AthkarWidgetLogic.effectiveIndex(
            storedPeriodKey = store.readPeriodKey(appWidgetId),
            storedIndex = store.readIndex(appWidgetId),
            currentPeriodKey = state.periodKey,
            setSize = set.size,
        )

        views.setTextViewText(R.id.athkar_widget_title, title)
        val advanceIntent = advanceIntent(context, appWidgetId)
        views.setOnClickPendingIntent(R.id.athkar_widget_body, advanceIntent)

        if (index >= set.size) {
            // Completed the set for this window occurrence.
            views.setTextViewText(
                R.id.athkar_widget_text,
                context.getString(R.string.widget_athkar_done),
            )
            views.setTextViewText(R.id.athkar_widget_progress, "")
            views.setViewVisibility(R.id.athkar_widget_count, View.GONE)
        } else {
            val item = set[index]
            views.setTextViewText(R.id.athkar_widget_text, item.text)
            views.setTextViewText(
                R.id.athkar_widget_progress,
                arabicDigits("${index + 1}/${set.size}"),
            )
            if (item.count > 1) {
                views.setViewVisibility(R.id.athkar_widget_count, View.VISIBLE)
                views.setTextViewText(
                    R.id.athkar_widget_count,
                    context.getString(
                        R.string.widget_athkar_count,
                        arabicDigits(item.count.toString()),
                    ),
                )
            } else {
                views.setViewVisibility(R.id.athkar_widget_count, View.GONE)
            }
        }
        return views
    }

    private fun advanceIntent(context: Context, appWidgetId: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            // Unique request code per instance so extras are not shared.
            REQUEST_ADVANCE_BASE + appWidgetId,
            Intent(context, AthkarWidgetProvider::class.java).apply {
                action = ACTION_ADVANCE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun openAthkarIntent(context: Context, period: AthkarPeriod): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_ATHKAR
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_PERIOD, period.name)
        }
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN_ATHKAR,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun scheduleBoundaryAlarm(context: Context, transitionMs: Long) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        try {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC,
                transitionMs + BOUNDARY_GRACE_MS,
                refreshPendingIntent(context),
            )
        } catch (e: SecurityException) {
            Log.w(TAG, "Boundary alarm rejected", e)
        }
    }

    private fun cancelBoundaryAlarm(context: Context) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(refreshPendingIntent(context))
    }

    private fun refreshPendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            REQUEST_REFRESH,
            Intent(context, AthkarWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    companion object {
        private const val TAG = "AthkarWidget"

        /** Must match MethodChannelLogic's broadcast naming scheme. */
        const val ACTION_REFRESH = "com.tilawa.app.widget.ATHKAR.ACTION_REFRESH"
        const val ACTION_ADVANCE = "com.tilawa.app.widget.athkar.ACTION_ADVANCE"
        const val ACTION_OPEN_ATHKAR =
            "com.tilawa.app.widget.athkar.ACTION_OPEN_ATHKAR"
        const val EXTRA_PERIOD = "athkar_period"
        private const val REQUEST_REFRESH = 0x41544852 // 'ATHR'
        private const val REQUEST_OPEN_ATHKAR = 0x41544F41 // 'ATOA'
        private const val REQUEST_ADVANCE_BASE = 0x100000
        private const val BOUNDARY_GRACE_MS = 2_000L

        private fun widgetIds(context: Context, manager: AppWidgetManager): IntArray =
            manager.getAppWidgetIds(
                ComponentName(context, AthkarWidgetProvider::class.java),
            )

        private val ARABIC_DIGITS =
            charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')

        internal fun arabicDigits(value: String): String = buildString {
            for (c in value) {
                append(if (c in '0'..'9') ARABIC_DIGITS[c - '0'] else c)
            }
        }
    }
}
