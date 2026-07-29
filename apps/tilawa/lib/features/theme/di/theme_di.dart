import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/theme/presentation/cubit/theme_cubit.dart';

/// Manual GetIt registrations for `theme`.
class ThemeDi {
  ThemeDi._();

  static void register(GetIt getIt) {
    getIt.registerFactoryIfAbsent<ThemeCubit>(
      ThemeCubit.new,
    );
  }
}
