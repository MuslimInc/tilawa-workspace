import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/support/data/datasources/play_billing_datasource.dart';
import 'package:tilawa/features/support/data/datasources/support_local_datasource.dart';
import 'package:tilawa/features/support/data/repositories/support_repository_impl.dart';
import 'package:tilawa/features/support/data/services/purchase_verification_client.dart';
import 'package:tilawa/features/support/domain/repositories/support_repository.dart';
import 'package:tilawa/features/support/domain/usecases/abort_pending_purchase_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/get_support_products_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/prepare_support_session_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/purchase_support_product_use_case.dart';
import 'package:tilawa/features/support/domain/usecases/restore_purchases_use_case.dart';
import 'package:tilawa/features/support/presentation/bloc/support_bloc.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Manual GetIt registrations for `support`.
class SupportDi {
  SupportDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<SupportLocalDataSource>(
      () => SupportLocalDataSourceImpl(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerLazySingletonIfAbsent<PlayBillingDataSource>(
      () => PlayBillingDataSourceImpl(getIt<InAppPurchase>()),
    );
    getIt.registerLazySingletonIfAbsent<PurchaseVerificationClient>(
      () => FirebasePurchaseVerificationClient(
        getIt<FirebaseFunctions>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SupportRepository>(
      () => SupportRepositoryImpl(
        getIt<PlayBillingDataSource>(),
        getIt<SupportLocalDataSource>(),
        getIt<PurchaseVerificationClient>(),
        getIt<AnalyticsService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AbortPendingPurchaseUseCase>(
      () => AbortPendingPurchaseUseCase(getIt<SupportRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetSupportProductsUseCase>(
      () => GetSupportProductsUseCase(getIt<SupportRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<PrepareSupportSessionUseCase>(
      () => PrepareSupportSessionUseCase(getIt<SupportRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<PurchaseSupportProductUseCase>(
      () => PurchaseSupportProductUseCase(getIt<SupportRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<RestorePurchasesUseCase>(
      () => RestorePurchasesUseCase(getIt<SupportRepository>()),
    );
    getIt.registerFactoryIfAbsent<SupportBloc>(
      () => SupportBloc(
        getIt<PrepareSupportSessionUseCase>(),
        getIt<GetSupportProductsUseCase>(),
        getIt<PurchaseSupportProductUseCase>(),
        getIt<RestorePurchasesUseCase>(),
        getIt<AbortPendingPurchaseUseCase>(),
        getIt<Connectivity>(),
        getIt<AnalyticsService>(),
      ),
    );
  }
}
