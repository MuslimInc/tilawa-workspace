import 'package:equatable/equatable.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

import 'home_prayer_day_boundaries.dart';

/// Data needed to render the main Home dashboard.
final class HomeDashboard extends Equatable {
  const HomeDashboard({
    required this.generatedAt,
    this.displayName,
    this.photoUrl,
    this.locationLabel,
    this.nextPrayer,
    this.prayerBoundaries,
  });

  /// Time the dashboard snapshot was generated.
  final DateTime generatedAt;

  /// Best available user-facing profile name.
  final String? displayName;

  /// Remote profile photo URL from Firebase Auth, when signed in.
  final String? photoUrl;

  /// Best available prayer location label.
  final String? locationLabel;

  /// Next main prayer for the dashboard location, if known.
  final HomeNextPrayer? nextPrayer;

  /// Today's prayer anchors for hero gradient phase resolution.
  final HomePrayerDayBoundaries? prayerBoundaries;

  bool get hasPrayerLocation => locationLabel != null && locationLabel != '';

  @override
  List<Object?> get props => [
    generatedAt,
    displayName,
    photoUrl,
    locationLabel,
    nextPrayer,
    prayerBoundaries,
  ];
}

/// Next-prayer summary for Home.
final class HomeNextPrayer extends Equatable {
  const HomeNextPrayer({
    required this.type,
    required this.time,
    required this.timeUntil,
  });

  final PrayerType type;
  final DateTime time;
  final Duration timeUntil;

  @override
  List<Object?> get props => [type, time, timeUntil];
}
