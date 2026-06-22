import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

/// MVP implementation of [ScheduleRepository] backed by the in-memory
/// [QuranSessionsMvpStore]. Mirrors the Firestore datasource's contract so the
/// weekly editor round-trips identically against fakes.
class FakeMvpScheduleRepository implements ScheduleRepository {
  FakeMvpScheduleRepository(this._store);

  final QuranSessionsMvpStore _store;

  @override
  Future<Either<QuranSessionsFailure, WeeklySchedule?>> getSchedule(
    String teacherId,
  ) async => Right(_store.schedules[teacherId]);

  @override
  Future<Either<QuranSessionsFailure, void>> saveSchedule(
    WeeklySchedule schedule,
  ) async {
    _store.schedules[schedule.teacherId] = schedule.copyWith(
      updatedAt: DateTime.now(),
    );
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, List<AvailabilityOverride>>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final all =
        _store.overrides[teacherId]?.values.toList() ??
        const <AvailabilityOverride>[];
    final fromDate = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final toDate = to == null ? null : DateTime(to.year, to.month, to.day);
    final filtered = all.where((o) {
      if (fromDate != null && o.date.isBefore(fromDate)) return false;
      if (toDate != null && !o.date.isBefore(toDate)) return false;
      return true;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    return Right(filtered);
  }

  @override
  Future<Either<QuranSessionsFailure, AvailabilityOverride?>> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async {
    final override = _store.overrides[teacherId]?[dateKey];
    return Right(override);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> saveOverride(
    String teacherId,
    AvailabilityOverride override,
  ) async {
    (_store.overrides[teacherId] ??= {})[override.dateKey] = override;
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> removeOverride(
    String teacherId,
    String dateKey,
  ) async {
    _store.overrides[teacherId]?.remove(dateKey);
    return const Right(null);
  }
}
