import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/settings/di/settings_di.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/features/theme/di/theme_di.dart';
import 'package:tilawa/features/theme/presentation/cubit/theme_cubit.dart';

void main() {
  group('GetItIdempotentRegistration', () {
    test('registerLazySingletonIfAbsent keeps first instance', () {
      final sl = GetIt.asNewInstance();
      var builds = 0;
      sl.registerLazySingletonIfAbsent<int>(() {
        builds++;
        return 1;
      });
      sl.registerLazySingletonIfAbsent<int>(() {
        builds++;
        return 2;
      });
      expect(sl<int>(), 1);
      expect(builds, 1);
    });

    test('registerFactoryIfAbsent returns new instances', () {
      final sl = GetIt.asNewInstance();
      sl.registerFactoryIfAbsent<_Token>(_Token.new);
      expect(sl<_Token>(), isNot(same(sl<_Token>())));
    });
  });

  group('feature Di modules', () {
    test('SettingsDi registers SettingsCubit', () {
      final sl = GetIt.asNewInstance();
      SettingsDi.register(sl);
      expect(sl.isRegistered<SettingsCubit>(), isTrue);
    });

    test('ThemeDi registers ThemeCubit', () {
      final sl = GetIt.asNewInstance();
      ThemeDi.register(sl);
      expect(sl.isRegistered<ThemeCubit>(), isTrue);
    });

    test('SettingsDi register is idempotent', () {
      final sl = GetIt.asNewInstance();
      SettingsDi.register(sl);
      SettingsDi.register(sl);
      expect(sl.isRegistered<SettingsCubit>(), isTrue);
    });
  });
}

class _Token {}
