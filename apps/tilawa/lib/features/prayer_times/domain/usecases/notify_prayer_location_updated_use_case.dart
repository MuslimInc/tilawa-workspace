import 'package:injectable/injectable.dart';

import '../../application/prayer_location_update_notifier.dart';

/// Notifies prayer-times consumers that saved scheduling location changed.
@lazySingleton
class NotifyPrayerLocationUpdatedUseCase {
  const NotifyPrayerLocationUpdatedUseCase(this._notifier);

  final PrayerLocationUpdateNotifier _notifier;

  void call({
    String? localeIdentifier,
    required PrayerLocationUpdateSource source,
  }) {
    _notifier.notifyLocationUpdated(
      localeIdentifier: localeIdentifier,
      source: source,
    );
  }
}
