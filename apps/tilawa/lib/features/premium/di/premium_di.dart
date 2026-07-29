import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/premium/data/datasources/premium_local_datasource.dart';
import 'package:tilawa/features/premium/data/datasources/premium_remote_datasource.dart';
import 'package:tilawa/features/premium/data/repositories/premium_repository_impl.dart';
import 'package:tilawa/features/premium/data/services/subscription_catalog_prefetch_impl.dart';
import 'package:tilawa/features/premium/data/services/subscription_plans_service.dart';
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart';
import 'package:tilawa/features/premium/domain/services/subscription_catalog_prefetch.dart';
import 'package:tilawa/features/premium/domain/usecases/cancel_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/check_feature_access_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/get_available_plans_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/get_premium_status_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/purchase_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/restore_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/start_trial_use_case.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_bloc.dart';

/// Manual GetIt registrations for `premium`.
class PremiumDi {
  PremiumDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<PremiumLocalDataSource>(
      () => PremiumLocalDataSourceImpl(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerLazySingletonIfAbsent<PremiumRemoteDataSource>(
      () => PremiumRemoteDataSourceImpl(
        getIt<FirebaseFirestore>(),
        getIt<FirebaseAuth>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SubscriptionCatalogPrefetch>(
      () => SubscriptionCatalogPrefetchImpl(
        getIt<SubscriptionPlansService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<PremiumRepository>(
      () => PremiumRepositoryImpl(
        getIt<PremiumLocalDataSource>(),
        getIt<PremiumRemoteDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<CancelSubscriptionUseCase>(
      () => CancelSubscriptionUseCase(getIt<PremiumRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<CheckFeatureAccessUseCase>(
      () => CheckFeatureAccessUseCase(getIt<PremiumRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetAvailablePlansUseCase>(
      () => GetAvailablePlansUseCase(getIt<PremiumRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetPremiumStatusUseCase>(
      () => GetPremiumStatusUseCase(getIt<PremiumRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<PurchaseSubscriptionUseCase>(
      () => PurchaseSubscriptionUseCase(getIt<PremiumRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<RestoreSubscriptionUseCase>(
      () => RestoreSubscriptionUseCase(getIt<PremiumRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<StartTrialUseCase>(
      () => StartTrialUseCase(getIt<PremiumRepository>()),
    );
    getIt.registerFactoryIfAbsent<PremiumBloc>(
      () => PremiumBloc(
        getIt<GetPremiumStatusUseCase>(),
        getIt<PurchaseSubscriptionUseCase>(),
        getIt<CancelSubscriptionUseCase>(),
        getIt<RestoreSubscriptionUseCase>(),
        getIt<StartTrialUseCase>(),
        getIt<GetAvailablePlansUseCase>(),
        getIt<CheckFeatureAccessUseCase>(),
      ),
    );
  }
}
