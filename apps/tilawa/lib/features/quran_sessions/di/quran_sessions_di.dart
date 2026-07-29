import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/quran_sessions/domain/services/session_taken_over_notifier.dart';

/// Manual GetIt registrations for `quran_sessions`.
class QuranSessionsDi {
  QuranSessionsDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<SessionTakenOverNotifier>(
      SessionTakenOverNotifier.new,
    );
  }
}
