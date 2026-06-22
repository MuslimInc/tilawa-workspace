import 'package:get_it/get_it.dart';

/// Idempotent [GetIt] registration helpers for partial init / hot reload.
extension GetItIdempotentRegistration on GetIt {
  void registerLazySingletonIfAbsent<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    if (!isRegistered<T>(instanceName: instanceName)) {
      registerLazySingleton<T>(factory, instanceName: instanceName);
    }
  }

  void registerFactoryIfAbsent<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    if (!isRegistered<T>(instanceName: instanceName)) {
      registerFactory<T>(factory, instanceName: instanceName);
    }
  }

  void registerSingletonOnce<T extends Object>(
    T instance, {
    String? instanceName,
  }) {
    if (!isRegistered<T>(instanceName: instanceName)) {
      registerSingleton<T>(instance, instanceName: instanceName);
    }
  }
}
