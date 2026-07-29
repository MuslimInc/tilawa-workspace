import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa_core/di/tilawa_core_di.dart';
import 'package:tilawa_core/network/network_info.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_core/services/interfaces/keep_awake_service.dart';
import 'package:tilawa_core/services/wakelock_keep_awake_service.dart';

void main() {
  late GetIt getIt;

  setUp(() async {
    getIt = GetIt.asNewInstance();
    getIt.registerLazySingleton<Connectivity>(Connectivity.new);
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('TilawaCoreDi.register resolves core types with correct lifecycles', () {
    TilawaCoreDi.register(getIt);

    expect(getIt.isRegistered<KeepAwakeService>(), isTrue);
    expect(getIt.isRegistered<NetworkInfo>(), isTrue);
    expect(getIt.isRegistered<InternetStatusBloc>(), isTrue);

    final keepAwakeA = getIt<KeepAwakeService>();
    final keepAwakeB = getIt<KeepAwakeService>();
    expect(keepAwakeA, same(keepAwakeB));
    expect(keepAwakeA, isA<WakelockKeepAwakeService>());

    final networkA = getIt<NetworkInfo>();
    final networkB = getIt<NetworkInfo>();
    expect(networkA, isNot(same(networkB)));

    // Factory registered; avoid constructing (listens to platform channel).
    expect(getIt.isRegistered<InternetStatusBloc>(), isTrue);
  });

  test('TilawaCoreDi.register is idempotent', () {
    TilawaCoreDi.register(getIt);
    TilawaCoreDi.register(getIt);
    expect(getIt.isRegistered<NetworkInfo>(), isTrue);
  });
}
