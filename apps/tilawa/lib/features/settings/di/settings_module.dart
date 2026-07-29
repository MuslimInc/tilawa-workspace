import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';

import '../domain/services/sleep_timer_settings.dart';
import '../presentation/cubit/settings_cubit.dart';

class SettingsModule {
  SettingsModule._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<SleepTimerSettings>(
      () => getIt<SettingsCubit>(),
    );
  }
}
