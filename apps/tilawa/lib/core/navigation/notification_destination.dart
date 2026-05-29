import 'navigation_source.dart';

/// A fully-resolved navigation target derived from a notification or deep link.
///
/// This is the single value object that every notification path (Athkar, prayer
/// Adhan, downloads, FCM, app links) produces and that [NotificationRouter]
/// consumes. It deliberately carries the already-resolved go_router [location]
/// plus an optional **decoded** [extra] (e.g. a `ReciterEntity` object, never a
/// pre-encoded JSON string) so the router can hand it straight to go_router's
/// `extraCodec` without double-encoding.
class NotificationDestination {
  const NotificationDestination({
    required this.location,
    this.extra,
    this.source = NavigationSource.notification,
  });

  /// go_router location string (path + query), e.g. `/athkar/1?source=notification`.
  final String location;

  /// Optional decoded route extra (object, not encoded JSON).
  final Object? extra;

  /// How the user reached this destination.
  final NavigationSource source;

  NotificationDestination copyWith({
    String? location,
    Object? extra,
    NavigationSource? source,
  }) {
    return NotificationDestination(
      location: location ?? this.location,
      extra: extra ?? this.extra,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationDestination &&
        other.location == location &&
        other.extra == extra &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(location, extra, source);

  @override
  String toString() =>
      'NotificationDestination(location: $location, source: ${source.wireValue}, '
      'hasExtra: ${extra != null})';
}
