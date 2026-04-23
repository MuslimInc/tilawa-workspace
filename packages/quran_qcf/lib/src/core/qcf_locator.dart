import 'package:get_it/get_it.dart';

import '../data/repositories/mushaf_service.dart';
import '../domain/repositories/quran_mushaf_service.dart';
import '../presentation/services/idle_scheduler.dart';
import '../presentation/services/page_snapshot_service.dart';
import '../presentation/services/quran_font_service.dart';
import '../presentation/services/quran_page_preparation_service.dart';

/// The [GetIt] instance scoped to the `quran_qcf` package.
///
/// Consumers must call [QuranQcfLocator.setup] once during app
/// initialisation (before any widget that uses the Quran reader is mounted).
/// Afterwards, services are resolved via [quranQcfLocator].
///
/// Example:
/// ```dart
/// // In your app bootstrap:
/// await QuranQcfLocator.setup();
/// ```
final GetIt quranQcfLocator = GetIt.asNewInstance();

/// Registers all `quran_qcf` services into [quranQcfLocator].
///
/// Idempotent — safe to call multiple times; subsequent calls are no-ops.
class QuranQcfLocator {
  QuranQcfLocator._();

  /// Registers services if they have not yet been registered.
  static void setup() {
    if (quranQcfLocator.isRegistered<QuranMushafService>()) return;

    // Create a single MushafService instance that is registered for both interfaces
    final mushafService = MushafService();

    quranQcfLocator
      ..registerSingleton<MushafService>(mushafService)
      ..registerSingleton<QuranMushafService>(mushafService)
      ..registerLazySingleton<IdleScheduler>(IdleScheduler.new)
      ..registerLazySingleton<QuranFontService>(
        () => QuranFontService(
          mushafService: quranQcfLocator<QuranMushafService>(),
          idleScheduler: quranQcfLocator<IdleScheduler>(),
        ),
      )
      ..registerLazySingleton<QuranPagePreparationService>(
        QuranPagePreparationService.new,
      )
      ..registerLazySingleton<PageSnapshotService>(
        () => PageSnapshotService(
          idleScheduler: quranQcfLocator<IdleScheduler>(),
        ),
      );
  }

  /// Resets all registrations. For use in tests only.
  static Future<void> resetForTests() => quranQcfLocator.reset();
}
