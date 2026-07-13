import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../islamic_widgets/app/wird_progress_widget_sync_service.dart';
import '../islamic_widgets/data/widget_snapshot_bridge.dart';

import 'data/datasources/khatma_plan_local_datasource.dart';
import 'data/repositories/khatma_plan_repository_impl.dart';
import 'domain/repositories/khatma_plan_repository.dart';
import 'domain/entities/khatma_plan.dart';
import 'domain/usecases/create_khatma_plan_use_case.dart';
import 'domain/usecases/extend_khatma_plan_use_case.dart';
import 'domain/usecases/get_active_khatma_plan_use_case.dart';
import 'domain/usecases/get_khatma_today_target_use_case.dart';
import 'domain/usecases/get_wird_progress_summary_use_case.dart';
import 'domain/usecases/reset_khatma_plan_use_case.dart';
import 'domain/usecases/update_khatma_plan_use_case.dart';
import 'domain/usecases/update_khatma_progress_use_case.dart';
import 'presentation/bloc/khatma_plan_bloc.dart';
import 'presentation/bloc/khatma_plan_event.dart';
import 'smart_khatma_feature_flags.dart';

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
    return GetKhatmaTodayTargetUseCase(repository);
  }

  static GetWirdProgressSummaryUseCase getWirdProgressSummary(
    KhatmaPlanRepository repository,
  ) {
    return GetWirdProgressSummaryUseCase(repository);
  }

  static KhatmaPlanBloc bloc() {
    final planRepository = repository();
    final analyticsService = getIt<AnalyticsService>();
    return KhatmaPlanBloc(
      GetActiveKhatmaPlanUseCase(planRepository),
      GetKhatmaTodayTargetUseCase(planRepository),
      CreateKhatmaPlanUseCase(
        planRepository,
        analyticsService,
      ),
      UpdateKhatmaPlanUseCase(planRepository, analyticsService),
      UpdateKhatmaProgressUseCase(
        planRepository,
        analyticsService,
        onProgressChanged: syncWirdWidget,
      ),
      ExtendKhatmaPlanUseCase(planRepository, analyticsService),
      ResetKhatmaPlanUseCase(planRepository, analyticsService),
      syncWirdWidget,
    )..add(const KhatmaPlanStarted());
  }

  static Future<int> currentQuranPage() async {
    final position = await getIt<QuranReaderRepository>().getLastReadPosition();
    return (position.page ?? KhatmaPlan.firstQuranPage).clamp(
      KhatmaPlan.firstQuranPage,
      KhatmaPlan.lastQuranPage,
    );
  }

  static Future<void> syncWirdWidget() async {
    if (!Platform.isAndroid || !isWirdWidgetEnabled()) return;
    final planRepository = repository();
    await WirdProgressWidgetSyncService(
      useCase: getWirdProgressSummary(planRepository),
      bridge: const WidgetSnapshotBridge(
        MethodChannel('com.tilawa.app/prayer_adhan'),
      ),
      prefs: getIt<SharedPreferencesAsync>(),
    ).syncIfNeeded();
  }
}
