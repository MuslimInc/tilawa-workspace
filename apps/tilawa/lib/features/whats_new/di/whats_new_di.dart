import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/whats_new/data/datasources/changelog_asset_data_source.dart';
import 'package:tilawa/features/whats_new/data/datasources/whats_new_progress_local_data_source.dart';
import 'package:tilawa/features/whats_new/data/repositories/changelog_repository_impl.dart';
import 'package:tilawa/features/whats_new/data/repositories/whats_new_progress_repository_impl.dart';
import 'package:tilawa/features/whats_new/domain/repositories/changelog_repository.dart';
import 'package:tilawa/features/whats_new/domain/repositories/whats_new_progress_repository.dart';
import 'package:tilawa/features/whats_new/domain/usecases/get_current_changelog_release_use_case.dart';
import 'package:tilawa/features/whats_new/domain/usecases/get_whats_new_eligibility_use_case.dart';
import 'package:tilawa/features/whats_new/domain/usecases/mark_whats_new_seen_use_case.dart';
import 'package:tilawa/features/whats_new/presentation/coordinators/whats_new_coordinator.dart';
import 'package:tilawa/features/whats_new/presentation/services/whats_new_presenter.dart';
import 'package:tilawa/features/whats_new/presentation/services/whats_new_sheet_presenter.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

/// Manual GetIt registrations for `whats_new`.
class WhatsNewDi {
  WhatsNewDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<WhatsNewProgressLocalDataSource>(
      () => WhatsNewProgressLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<WhatsNewPresenter>(
      WhatsNewSheetPresenter.new,
    );
    getIt.registerLazySingletonIfAbsent<ChangelogAssetDataSource>(
      ChangelogAssetDataSourceImpl.new,
    );
    getIt.registerLazySingletonIfAbsent<WhatsNewProgressRepository>(
      () => WhatsNewProgressRepositoryImpl(
        getIt<WhatsNewProgressLocalDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ChangelogRepository>(
      () => ChangelogRepositoryImpl(
        getIt<ChangelogAssetDataSource>(),
        getIt<AppInfoService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetCurrentChangelogReleaseUseCase>(
      () => GetCurrentChangelogReleaseUseCase(
        getIt<ChangelogRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<MarkWhatsNewSeenUseCase>(
      () => MarkWhatsNewSeenUseCase(getIt<WhatsNewProgressRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetWhatsNewEligibilityUseCase>(
      () => GetWhatsNewEligibilityUseCase(
        getIt<GetCurrentChangelogReleaseUseCase>(),
        getIt<WhatsNewProgressRepository>(),
        getIt<CheckOnboardingStatus>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<WhatsNewCoordinator>(
      () => WhatsNewCoordinator(
        getIt<GetWhatsNewEligibilityUseCase>(),
        getIt<GetCurrentChangelogReleaseUseCase>(),
        getIt<MarkWhatsNewSeenUseCase>(),
        getIt<WhatsNewPresenter>(),
        getIt<AnalyticsService>(),
      ),
    );
  }
}
