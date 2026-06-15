import 'dart:async';

import 'package:injectable/injectable.dart';

/// Which screen initiated a saved prayer-location change.
enum PrayerLocationUpdateSource { homeDashboard, prayerTimesTab }

/// Broadcasts when saved prayer scheduling coordinates changed.
@lazySingleton
class PrayerLocationUpdateNotifier {
  final StreamController<PrayerLocationUpdate> _controller =
      StreamController<PrayerLocationUpdate>.broadcast();

  Stream<PrayerLocationUpdate> get stream => _controller.stream;

  void notifyLocationUpdated({
    String? localeIdentifier,
    required PrayerLocationUpdateSource source,
  }) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(
      PrayerLocationUpdate(
        localeIdentifier: localeIdentifier,
        source: source,
      ),
    );
  }
}

/// Payload for [PrayerLocationUpdateNotifier.stream].
final class PrayerLocationUpdate {
  const PrayerLocationUpdate({
    this.localeIdentifier,
    required this.source,
  });

  final String? localeIdentifier;
  final PrayerLocationUpdateSource source;
}
