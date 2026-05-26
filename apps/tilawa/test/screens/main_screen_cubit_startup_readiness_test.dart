import 'package:dartz_plus/dartz_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'main_screen_cubit_startup_readiness_test.mocks.dart';

@GenerateMocks([GetRecitersUseCase, GetFavoriteRecitersUseCase])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(
    const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
  );

  late MockGetRecitersUseCase mockGetReciters;
  late MockGetFavoriteRecitersUseCase mockGetFavorites;
  late AppStartupReadiness readiness;

  setUp(() {
    mockGetReciters = MockGetRecitersUseCase();
    mockGetFavorites = MockGetFavoriteRecitersUseCase();
    readiness = AppStartupReadiness(mockGetReciters, mockGetFavorites);
    when(mockGetReciters.call()).thenAnswer(
      (_) async =>
          const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
    );
    when(mockGetFavorites.call(any)).thenAnswer(
      (_) async =>
          const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
    );
  });

  group('MainScreenCubit startup readiness', () {
    test('starts with shell and tab ready when splash prep completed', () async {
      await readiness.waitUntilReady(prepareShell: true);
      final cubit = MainScreenCubit(readiness: readiness);

      expect(cubit.state.isShellActivated, isTrue);
      expect(cubit.state.isInitialTabMounted, isTrue);
      expect(cubit.state.builtTabIndexes, contains(0));
      expect(cubit.state.isStartupUiWarm, isFalse);

      await cubit.close();
    });

    test('starts deferred when splash prep did not run', () {
      final cubit = MainScreenCubit(readiness: readiness);

      expect(cubit.state.isShellActivated, isFalse);
      expect(cubit.state.isInitialTabMounted, isFalse);
      expect(cubit.state.builtTabIndexes, isEmpty);

      cubit.close();
    });

    test('activates shell after delay when prep not done on splash', () {
      fakeAsync((FakeAsync async) {
        final cubit = MainScreenCubit(readiness: readiness);

        async.elapse(AppStartupReadiness.shellActivationDelay);
        expect(cubit.state.isShellActivated, isTrue);

        async.elapse(
          AppStartupReadiness.initialTabRouteSettleDelay -
              AppStartupReadiness.shellActivationDelay,
        );
        expect(cubit.state.isInitialTabMounted, isTrue);

        cubit.close();
      });
    });
  });
}
