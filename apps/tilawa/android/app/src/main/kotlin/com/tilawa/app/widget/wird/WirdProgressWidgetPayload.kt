package com.tilawa.app.widget.wird

import org.json.JSONObject

/** Text ordering the widget must lay out with. */
internal enum class WirdWidgetTextDirection(val wireName: String) {
    LTR("ltr"),
    RTL("rtl"),
    ;

    companion object {
        fun fromWireName(wireName: String): WirdWidgetTextDirection? =
            entries.firstOrNull { it.wireName == wireName }
    }
}

/**
 * Semantic tap action passed through from Spec 023. Concrete route resolution
 * (the `openKhatma` widget-bridge action) is deliberately deferred to
 * T-041A1-d; this type only decodes the intent.
 */
internal enum class WirdWidgetAction(val wireName: String) {
    CREATE_PLAN("createPlan"),
    OPEN_TODAY_WIRD("openTodayWird"),
    VIEW_COMPLETED_PLAN("viewCompletedPlan"),
    ;

    companion object {
        fun fromWireName(wireName: String): WirdWidgetAction? =
            entries.firstOrNull { it.wireName == wireName }
    }
}

/**
 * Parsed payload of a Daily Wird / Khatma progress snapshot (spec 041
 * amendment 041-A1, T-041A1-c decode half). The Kotlin counterpart of the
 * Flutter `WirdProgressWidgetPayload.tryParse`: the widget renders these
 * display-ready strings verbatim and performs no localization, digit
 * formatting, or plan math (Contract B invariant).
 *
 * Freshness (`generatedAt`/`expiresAt`/`isStale`) is intentionally omitted —
 * the enclosing [com.tilawa.app.widget.WidgetSnapshotEnvelope] owns
 * `generatedAtMs`/`validUntilMs`, and staleness is re-derived at render time.
 */
internal data class WirdProgressWidgetPayload(
    val locale: String,
    val textDirection: WirdWidgetTextDirection,
    val localizedTitle: String,
    val localizedSubtitle: String,
    val formattedAssignedAmount: String,
    val formattedCompletedAmount: String,
    val formattedRemainingAmount: String,
    val progressValue: Double,
    val accessibilityLabel: String,
    val action: WirdWidgetAction,
) {
    companion object {
        /**
         * Returns null when any required field is missing or invalid so the
         * caller renders the setup/no-data state instead of a broken frame
         * (FR-041A1.9). Mirrors the Flutter tolerant parser.
         */
        fun parse(payload: JSONObject): WirdProgressWidgetPayload? {
            val locale = payload.optString("locale")
            val textDirection = WirdWidgetTextDirection.fromWireName(
                payload.optString("textDirection"),
            ) ?: return null
            val title = payload.optString("localizedTitle")
            val subtitle = payload.optString("localizedSubtitle")
            val assigned = payload.optString("formattedAssignedAmount")
            val completed = payload.optString("formattedCompletedAmount")
            val remaining = payload.optString("formattedRemainingAmount")
            val accessibilityLabel = payload.optString("accessibilityLabel")
            val action = WirdWidgetAction.fromWireName(
                payload.optString("action"),
            ) ?: return null
            val progress = payload.optDouble("progressValue", Double.NaN)

            if (locale.isBlank() ||
                title.isBlank() ||
                subtitle.isBlank() ||
                assigned.isBlank() ||
                completed.isBlank() ||
                remaining.isBlank() ||
                accessibilityLabel.isBlank()
            ) {
                return null
            }
            if (progress.isNaN() || progress < 0.0 || progress > 1.0) return null

            return WirdProgressWidgetPayload(
                locale = locale,
                textDirection = textDirection,
                localizedTitle = title,
                localizedSubtitle = subtitle,
                formattedAssignedAmount = assigned,
                formattedCompletedAmount = completed,
                formattedRemainingAmount = remaining,
                progressValue = progress,
                accessibilityLabel = accessibilityLabel,
                action = action,
            )
        }
    }
}
