import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/app_review/domain/usecases/open_app_store_listing_use_case.dart';
import 'package:tilawa/features/forced_update/data/datasources/default_forced_update_host_platform_resolver.dart';
import 'package:tilawa/features/forced_update/data/datasources/firestore_forced_update_config_remote_data_source.dart';
import 'package:tilawa/features/forced_update/data/datasources/forced_update_config_remote_data_source.dart';
import 'package:tilawa/features/forced_update/data/repositories/forced_update_repository_impl.dart';
import 'package:tilawa/features/forced_update/domain/repositories/forced_update_repository.dart';
import 'package:tilawa/features/forced_update/domain/services/forced_update_evaluator.dart';
import 'package:tilawa/features/forced_update/domain/services/forced_update_host_platform_resolver.dart';
import 'package:tilawa/features/forced_update/domain/usecases/evaluate_forced_update_use_case.dart';
import 'package:tilawa/features/forced_update/presentation/coordinators/forced_update_coordinator.dart';
import 'package:tilawa/features/forced_update/presentation/services/forced_update_gate_presenter.dart';
import 'package:tilawa/features/forced_update/presentation/services/navigator_forced_update_gate_presenter.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

/// Manual GetIt registrations for `forced_update`.
class ForcedUpdateDi {
  ForcedUpdateDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<ForcedUpdateEvaluator>(
      () => const ForcedUpdateEvaluator(),
    );
    getIt.registerLazySingletonIfAbsent<ForcedUpdateGatePresenter>(
      NavigatorForcedUpdateGatePresenter.new,
    );
    getIt.registerLazySingletonIfAbsent<ForcedUpdateHostPlatformResolver>(
      () => const DefaultForcedUpdateHostPlatformResolver(),
    );
    getIt.registerLazySingletonIfAbsent<ForcedUpdateConfigRemoteDataSource>(
      () => FirestoreForcedUpdateConfigRemoteDataSource(
        getIt<FirebaseFirestore>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ForcedUpdateRepository>(
      () => ForcedUpdateRepositoryImpl(
        getIt<ForcedUpdateConfigRemoteDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<EvaluateForcedUpdateUseCase>(
      () => EvaluateForcedUpdateUseCase(
        getIt<ForcedUpdateRepository>(),
        getIt<AppInfoService>(),
        getIt<ForcedUpdateEvaluator>(),
        getIt<ForcedUpdateHostPlatformResolver>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ForcedUpdateCoordinator>(
      () => ForcedUpdateCoordinator(
        getIt<EvaluateForcedUpdateUseCase>(),
        getIt<OpenAppStoreListingUseCase>(),
        getIt<ForcedUpdateGatePresenter>(),
      ),
    );
  }
}
