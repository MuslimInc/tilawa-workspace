/// Supported Android home-screen widget types.
enum IslamicWidgetType { prayer, ayah, athkar, hijri }

/// Host layout classes shared by Flutter snapshot producers and Android.
enum IslamicWidgetSizeClass { compact, expanded }

/// Appearance choices stored per widget instance.
enum IslamicWidgetTheme { light, dark, automatic }

/// A versioned display snapshot handed to a native widget provider.
class WidgetSnapshotEnvelope<T extends Object> {
  WidgetSnapshotEnvelope({
    required this.schemaVersion,
    required this.widgetType,
    required this.generatedAt,
    required this.payload,
    this.validUntil,
  }) : assert(schemaVersion > 0),
       assert(validUntil == null || !validUntil.isBefore(generatedAt));

  /// Contract version understood by the snapshot producer and consumer.
  final int schemaVersion;

  /// Widget provider that may consume [payload].
  final IslamicWidgetType widgetType;

  /// Time at which the snapshot was produced.
  final DateTime generatedAt;

  /// First instant at which the host should request a replacement snapshot.
  final DateTime? validUntil;

  /// Display-ready, widget-specific content.
  final T payload;

  /// Whether this snapshot has crossed its declared freshness boundary.
  bool isStaleAt(DateTime instant) {
    final DateTime? freshnessBoundary = validUntil;
    return freshnessBoundary != null && !instant.isBefore(freshnessBoundary);
  }
}

/// Actions a native widget host may send back to the Flutter application.
enum IslamicWidgetActionType {
  openPrayerTimes,
  openAyah,
  openAthkar,
  openHijriSettings,
  advanceAthkar,
  openWidgetSetup,
}

/// A privacy-safe command emitted by a placed widget instance.
class IslamicWidgetAction {
  const IslamicWidgetAction({
    required this.type,
    required this.widgetType,
    required this.appWidgetId,
    this.arguments = const <String, Object?>{},
  }) : assert(appWidgetId > 0);

  /// Requested application behavior.
  final IslamicWidgetActionType type;

  /// Widget type that emitted this action.
  final IslamicWidgetType widgetType;

  /// Host identifier used only for local per-instance state.
  final int appWidgetId;

  /// Route or interaction arguments that contain no user content or location.
  final Map<String, Object?> arguments;
}
