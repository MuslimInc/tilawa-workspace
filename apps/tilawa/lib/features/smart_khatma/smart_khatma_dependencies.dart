import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import 'data/datasources/khatma_plan_local_datasource.dart';
import 'data/repositories/khatma_plan_repository_impl.dart';
import 'domain/repositories/khatma_plan_repository.dart';
import 'domain/usecases/create_khatma_plan_use_case.dart';
import 'domain/usecases/extend_khatma_plan_use_case.dart';
import 'domain/usecases/get_active_khatma_plan_use_case.dart';
import 'domain/usecases/get_khatma_today_target_use_case.dart';
import 'domain/usecases/get_wird_progress_summary_use_case.dart';
import 'domain/usecases/reset_khatma_plan_use_case.dart';
import 'domain/usecases/select_khatma_catch_up_use_case.dart';
import 'domain/usecases/update_khatma_progress_use_case.dart';
import 'presentation/bloc/khatma_plan_bloc.dart';
import 'presentation/bloc/khatma_plan_event.dart';

final class SmartKhatmaDependencies {
  const SmartKhatmaDependencies._();

  static KhatmaPlanRepository repository() {
    return KhatmaPlanRepositoryImpl(
      SharedPreferencesKhatmaPlanLocalDataSource(
        getIt<SharedPreferencesAsync>(),
      ),
    );
  }

  static GetKhatmaTodayTargetUseCase getTodayTarget(
    KhatmaPlanRepository repository,
  ) {
    return GetKhatmaTodayTargetUseCase(
      repository,
      getIt<QuranReaderRepository>(),
    );
  }

  static GetWirdProgressSummaryUseCase getWirdProgressSummary(
    KhatmaPlanRepository repository,
  ) {
    return GetWirdProgressSummaryUseCase(repository);
  }

  static KhatmaPlanBloc bloc() {
    final planRepository = repository();
    final quranReaderRepository = getIt<QuranReaderRepository>();
    final analyticsService = getIt<AnalyticsService>();
    return KhatmaPlanBloc(
      GetActiveKhatmaPlanUseCase(planRepository),
      GetKhatmaTodayTargetUseCase(planRepository, quranReaderRepository),
      CreateKhatmaPlanUseCase(
        planRepository,
        quranReaderRepository,
        analyticsService,
      ),
      SelectKhatmaCatchUpUseCase(planRepository, analyticsService),
      ExtendKhatmaPlanUseCase(planRepository, analyticsService),
      ResetKhatmaPlanUseCase(planRepository, analyticsService),
    )..add(const KhatmaPlanStarted());
  }

  static UpdateKhatmaProgressUseCase updateProgress() {
    return UpdateKhatmaProgressUseCase(
      repository(),
      getIt<AnalyticsService>(),
    );
  }
}
