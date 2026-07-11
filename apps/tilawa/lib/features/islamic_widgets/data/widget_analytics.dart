import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import '../domain/entities/widget_snapshot_envelope.dart';

/// Analytics proxy for tracking Islamic Widget lifecycle and user interactions.
class WidgetAnalytics {
  const WidgetAnalytics(this._analyticsService);

  final AnalyticsService _analyticsService;

  /// Tracks when a snapshot payload is successfully pushed to the native side.
  void logSnapshotGenerated(IslamicWidgetType type) {
    _analyticsService.logEvent(
      AnalyticsEvents.widgetSnapshotGenerated,
      parameters: <String, Object>{
        AnalyticsParams.widgetType: type.name,
      },
    );
  }

  /// Tracks when an intent deep-link is resolved from the native side.
  void logWidgetTapped(IslamicWidgetAction action) {
    _analyticsService.logEvent(
      AnalyticsEvents.widgetTapped,
      parameters: <String, Object>{
        AnalyticsParams.widgetType: action.widgetType.name,
        AnalyticsParams.widgetAction: action.type.name,
      },
    );
  }
}
