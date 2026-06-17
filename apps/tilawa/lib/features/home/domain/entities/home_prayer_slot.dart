import 'package:equatable/equatable.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

/// One main prayer in today's Home schedule strip.
final class HomePrayerSlot extends Equatable {
  const HomePrayerSlot({
    required this.type,
    required this.time,
    required this.isNext,
    required this.hasPassed,
  });

  final PrayerType type;
  final DateTime time;
  final bool isNext;
  final bool hasPassed;

  @override
  List<Object?> get props => [type, time, isNext, hasPassed];
}
