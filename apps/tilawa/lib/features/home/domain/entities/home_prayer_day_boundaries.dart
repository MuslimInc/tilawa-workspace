import 'package:equatable/equatable.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

/// Prayer-time anchors used to resolve the home hero atmospheric gradient.
final class HomePrayerDayBoundaries extends Equatable {
  const HomePrayerDayBoundaries({
    required this.fajr,
    required this.sunrise,
    required this.maghrib,
    required this.isha,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime maghrib;
  final DateTime isha;

  factory HomePrayerDayBoundaries.fromPrayerTimes(
    PrayerTimeEntity prayerTimes,
  ) {
    return HomePrayerDayBoundaries(
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
  }

  @override
  List<Object?> get props => [fajr, sunrise, maghrib, isha];
}
