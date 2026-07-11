package com.tilawa.app.prayer.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import android.icu.text.SimpleDateFormat
import android.icu.util.IslamicCalendar
import com.tilawa.app.MainActivity
import com.tilawa.app.R
import java.util.Date
import java.util.Locale

/**
 * Home-screen prayer times widget (spec 041, User Story 1).
 *
 * Renders the five daily prayers with the next prayer highlighted and a live
 * countdown. The countdown is a [android.widget.Chronometer] in countdown
 * mode: it ticks inside the launcher process only while visible, so the
 * widget needs **zero** background wakeups between prayer boundaries.
 *
 * Refresh strategy (battery-safe by design, spec SC-007):
 *  - `updatePeriodMillis` (30 min) is the OS-managed backstop.
 *  - One inexact `setAndAllowWhileIdle` alarm at the next prayer boundary
 *    flips the highlight. Inexact is deliberate: a few minutes of Doze delay
 *    only matters while the screen is off, and the backstop covers wake-up.
 *  - Data refreshes arrive via [notifySnapshotUpdated] whenever Flutter's
 *    schedule pass pushes a new snapshot over the method channel.
 */
internal class PrayerTimesWidgetProvider : AppWidgetProvider() {

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
        cancelBoundaryAlarm(context)
        super.onDisabled(context)
    }

    private fun renderAll(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        if (appWidgetIds.isEmpty()) return
        val snapshot = PrayerWidgetStore(context).readSnapshot()
        val state = snapshot?.let {
            PrayerWidgetLogic.resolveState(it, System.currentTimeMillis())
        }
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, state))
        }
        scheduleBoundaryAlarm(context, state)
    }

    private fun buildViews(context: Context, state: PrayerWidgetState?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))

        if (state == null) {
            views.setViewVisibility(R.id.widget_content, View.GONE)
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            return views
        }
        views.setViewVisibility(R.id.widget_content, View.VISIBLE)
        views.setViewVisibility(R.id.widget_empty, View.GONE)

        // Header: location + countdown (or stale cue).
        bindLeftPanelMeta(views, state)
        val nextMs = state.nextPrayerTimeMs
        if (nextMs != null) {
            views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
            views.setViewVisibility(R.id.widget_stale, View.GONE)
            views.setTextViewText(
                R.id.widget_next_label,
                context.getString(
                    R.string.widget_next_prayer,
                    prayerLabel(context, state.nextPrayerKey!!),
                ),
            )
            views.setChronometerCountDown(R.id.widget_countdown, true)
            views.setChronometer(
                R.id.widget_countdown,
                SystemClock.elapsedRealtime() + (nextMs - System.currentTimeMillis()),
                null,
                true,
            )
        } else {
            views.setViewVisibility(R.id.widget_countdown, View.GONE)
            views.setViewVisibility(R.id.widget_stale, View.VISIBLE)
            views.setTextViewText(R.id.widget_next_label, "")
            views.setTextViewText(
                R.id.widget_stale,
                context.getString(if (state.locationName.isBlank()) R.string.widget_setup_hint else R.string.widget_stale_hint),
            )
        }

        // Prayer rows (sunrise included for display only).
        val timeFormat = android.text.format.DateFormat.getTimeFormat(context)
        for ((key, timeMs) in state.day.displayRows) {
            val ids = CELL_IDS.getValue(key)
            val isNext = key == state.nextPrayerKey
            views.setTextViewText(ids.nameId, prayerLabel(context, key))
            views.setTextViewText(
                ids.timeId,
                if (timeMs > 0L) timeFormat.format(Date(timeMs)) else "--:--",
            )
            views.setTextColor(
                ids.nameId,
                context.getColor(
                    if (isNext) R.color.widget_next_row else R.color.widget_text_secondary,
                ),
            )
            views.setTextColor(
                ids.timeId,
                context.getColor(
                    if (isNext) R.color.widget_next_row else R.color.widget_text_primary,
                ),
            )
            views.setInt(
                ids.cellId,
                "setBackgroundResource",
                if (isNext) R.drawable.widget_cell_highlight else 0,
            )
        }
        return views
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_PRAYER_TIMES
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN_APP,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun prayerLabel(context: Context, key: String): String = when (key) {
        PrayerWidgetDay.KEY_FAJR -> context.getString(R.string.prayer_fajr)
        PrayerWidgetDay.KEY_SUNRISE -> context.getString(R.string.prayer_sunrise)
        PrayerWidgetDay.KEY_DHUHR -> context.getString(R.string.prayer_dhuhr)
        PrayerWidgetDay.KEY_ASR -> context.getString(R.string.prayer_asr)
        PrayerWidgetDay.KEY_MAGHRIB -> context.getString(R.string.prayer_maghrib)
        PrayerWidgetDay.KEY_ISHA -> context.getString(R.string.prayer_isha)
        else -> key
    }

    private fun bindLeftPanelMeta(views: RemoteViews, state: PrayerWidgetState) {
        val locale = Locale.getDefault()
        val anchorDate = Date(state.day.fajrMs)
        val dayFormatter = SimpleDateFormat("EEEE", locale)
        val gregorianFormatter = SimpleDateFormat("yyyy-MM-dd", locale)
        val hijriFormatter = SimpleDateFormat("yyyy-MM-dd", locale).apply {
            calendar = IslamicCalendar(locale)
        }
        views.setTextViewText(R.id.widget_day_name, dayFormatter.format(anchorDate))
        views.setTextViewText(R.id.widget_hijri_date, hijriFormatter.format(anchorDate))
        views.setTextViewText(R.id.widget_gregorian_date, gregorianFormatter.format(anchorDate))
    }

    private fun scheduleBoundaryAlarm(context: Context, state: PrayerWidgetState?) {
        val triggerAt = state?.let(PrayerWidgetLogic::nextRefreshAtMs)
        if (triggerAt == null) {
            cancelBoundaryAlarm(context)
            return
        }
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        try {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC,
                triggerAt,
                refreshPendingIntent(context),
            )
        } catch (e: SecurityException) {
            // Never let widget refresh scheduling take the process down.
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
            Intent(context, PrayerTimesWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private data class CellIds(val cellId: Int, val nameId: Int, val timeId: Int)

    companion object {
        private const val TAG = "PrayerWidget"
        const val ACTION_REFRESH = "com.tilawa.app.prayer.widget.ACTION_REFRESH"
        const val ACTION_OPEN_PRAYER_TIMES =
            "com.tilawa.app.prayer.widget.ACTION_OPEN_PRAYER_TIMES"
        private const val REQUEST_REFRESH = 0x50575247 // 'PWRG'
        private const val REQUEST_OPEN_APP = 0x50574F41 // 'PWOA'

        private val CELL_IDS = mapOf(
            PrayerWidgetDay.KEY_FAJR to CellIds(
                R.id.widget_cell_fajr, R.id.widget_name_fajr, R.id.widget_time_fajr,
            ),
            PrayerWidgetDay.KEY_SUNRISE to CellIds(
                R.id.widget_cell_sunrise, R.id.widget_name_sunrise, R.id.widget_time_sunrise,
            ),
            PrayerWidgetDay.KEY_DHUHR to CellIds(
                R.id.widget_cell_dhuhr, R.id.widget_name_dhuhr, R.id.widget_time_dhuhr,
            ),
            PrayerWidgetDay.KEY_ASR to CellIds(
                R.id.widget_cell_asr, R.id.widget_name_asr, R.id.widget_time_asr,
            ),
            PrayerWidgetDay.KEY_MAGHRIB to CellIds(
                R.id.widget_cell_maghrib, R.id.widget_name_maghrib, R.id.widget_time_maghrib,
            ),
            PrayerWidgetDay.KEY_ISHA to CellIds(
                R.id.widget_cell_isha, R.id.widget_name_isha, R.id.widget_time_isha,
            ),
        )

        private fun widgetIds(context: Context, manager: AppWidgetManager): IntArray =
            manager.getAppWidgetIds(
                ComponentName(context, PrayerTimesWidgetProvider::class.java),
            )

        /**
         * Re-renders every placed widget. Called from the method channel after
         * Flutter pushes a fresh snapshot.
         */
        fun notifySnapshotUpdated(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = widgetIds(context, manager)
            if (ids.isEmpty()) return
            context.sendBroadcast(
                Intent(context, PrayerTimesWidgetProvider::class.java).apply {
                    action = ACTION_REFRESH
                },
            )
        }
    }
}
