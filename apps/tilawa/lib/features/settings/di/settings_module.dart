import 'package:injectable/injectable.dart';

import '../domain/services/sleep_timer_settings.dart';
import '../presentation/cubit/settings_cubit.dart';

@module
abstract class SettingsModule {
  @lazySingleton
  SleepTimerSettings sleepTimerSettings(SettingsCubit cubit) => cubit;
}
