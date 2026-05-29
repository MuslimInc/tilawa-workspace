/// Where a navigation request originated.
///
/// Used for analytics attribution and to keep a single, typed vocabulary for
/// how the user reached a destination. Replaces the previous ad-hoc string
/// `source` values scattered across routes (e.g. the hardcoded `'manual'` that
/// caused notification-opened Athkar to be mis-attributed).
enum NavigationSource {
  /// Opened by tapping a local or push notification.
  notification('notification'),

  /// Opened via an external deep link (app link / URL).
  deepLink('deep_link'),

  /// Opened by the user navigating inside the app.
  manual('manual');

  const NavigationSource(this.wireValue);

  /// Stable string used in route query params and analytics. Kept stable so
  /// existing route URLs and dashboards do not change.
  final String wireValue;

  /// Parses a [wireValue] back into a [NavigationSource], defaulting to
  /// [NavigationSource.manual] for unknown/legacy values.
  static NavigationSource fromWire(String? value) {
    for (final NavigationSource source in NavigationSource.values) {
      if (source.wireValue == value) {
        return source;
      }
    }
    return NavigationSource.manual;
  }
}
