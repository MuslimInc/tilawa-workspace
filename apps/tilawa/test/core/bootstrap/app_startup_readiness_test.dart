import 'package:dartz_plus/dartz_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'app_startup_readiness_test.mocks.dart';

@GenerateMocks([GetRecitersUseCase, GetFavoriteRecitersUseCase])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(
    const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
  );

  const ReciterEntity sampleReciter = ReciterEntity(
    id: 1,
    name: 'Sample',
    letter: 'S',
    date: '',
    moshaf: [],
  );

  late AppStartupReadiness readiness;
  late MockGetRecitersUseCase mockGetReciters;
  late MockGetFavoriteRecitersUseCase mockGetFavorites;

  setUp(() {
    mockGetReciters = MockGetRecitersUseCase();
    mockGetFavorites = MockGetFavoriteRecitersUseCase();
    when(mockGetFavorites.call(any)).thenAnswer(
      (_) async => const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
    );
    readiness = AppStartupReadiness(mockGetReciters, mockGetFavorites);
  });

  group('waitUntilReady(prepareShell: false)', () {
    test('does not touch reciters or shell flags', () async {
      await readiness.waitUntilReady(prepareShell: false);

      expect(readiness.shellPrepComplete, isFalse);
      expect(readiness.recitersDataReady, isFalse);
      expect(readiness.timedOut, isFalse);
      verifyNever(mockGetReciters.call());
      verifyNever(mockGetFavorites.call(any));
    });
  });

  group('waitUntilReady(prepareShell: true)', () {
    test(
      'preloads reciters + favorites and marks shell prep complete',
      () async {
        when(mockGetReciters.call()).thenAnswer(
          (_) async =>
              const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
        );
        when(mockGetFavorites.call(any)).thenAnswer(
          (_) async => const Right<Failure, List<ReciterEntity>>([
            sampleReciter,
          ]),
        );

        await readiness.waitUntilReady(prepareShell: true);

        expect(readiness.shellPrepComplete, isTrue);
        expect(readiness.recitersDataReady, isTrue);
        expect(readiness.timedOut, isFalse);
        verify(mockGetReciters.call()).called(1);
        verify(mockGetFavorites.call(any)).called(1);
      },
    );

    test('sets recitersDataReady false when fetch fails', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async => Left<Failure, List<ReciterEntity>>(
          UnexpectedFailure('network'),
        ),
      );

      await readiness.waitUntilReady(prepareShell: true);

      expect(readiness.shellPrepComplete, isTrue);
      expect(readiness.recitersDataReady, isFalse);
    });

    test('favorites failure does not block shell prep', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async =>
            const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
      );
      when(mockGetFavorites.call(any)).thenAnswer(
        (_) async =>
            Left<Failure, List<ReciterEntity>>(CacheFailure('no auth')),
      );

      await readiness.waitUntilReady(prepareShell: true);

      expect(readiness.shellPrepComplete, isTrue);
      expect(readiness.recitersDataReady, isTrue);
    });

    test('second call is a no-op after success', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async => const Right<Failure, List<ReciterEntity>>([
          sampleReciter,
        ]),
      );
      await readiness.waitUntilReady(prepareShell: true);
      await readiness.waitUntilReady(prepareShell: true);

      verify(mockGetReciters.call()).called(1);
    });

    test(
      'hanging reciters fetch is bounded by prefetchTimeout, not maxSplashDuration',
      () {
        fakeAsync((FakeAsync async) {
          when(mockGetReciters.call()).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(seconds: 30));
            return const Right<Failure, List<ReciterEntity>>([]);
          });

          var completed = false;
          readiness
              .waitUntilReady(prepareShell: true)
              .then((_) => completed = true);

          // Just after the per-prefetch cap + shell delay, prep should be done
          // and the splash should not have hit the 10s safety net.
          async.elapse(
            AppStartupReadiness.prefetchTimeout +
                AppStartupReadiness.initialTabRouteSettleDelay,
          );
          async.flushMicrotasks();

          expect(completed, isTrue);
          expect(readiness.shellPrepComplete, isTrue);
          expect(readiness.recitersDataReady, isFalse);
          expect(readiness.timedOut, isFalse);
        });
      },
    );
  });

  group('warmShellPrepInBackground', () {
    test('starts shell prep without blocking caller', () {
      when(mockGetReciters.call()).thenAnswer(
        (_) async => Future<Either<Failure, List<ReciterEntity>>>.delayed(
          const Duration(milliseconds: 500),
          () => const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[
            sampleReciter,
          ]),
        ),
      );

      fakeAsync((FakeAsync async) {
        readiness.warmShellPrepInBackground();
        expect(readiness.shellPrepComplete, isFalse);
        async.elapse(AppStartupReadiness.maxSplashDuration);
        async.flushMicrotasks();
        expect(readiness.shellPrepComplete, isTrue);
      });
    });

    test('is a no-op when shell prep already finished', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async =>
            const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
      );
      await readiness.waitUntilReady(prepareShell: true);

      readiness.warmShellPrepInBackground();
      await Future<void>.delayed(Duration.zero);

      verify(mockGetReciters.call()).called(1);
    });
  });

  group('resetForTesting', () {
    test('clears flags', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async =>
            const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
      );
      await readiness.waitUntilReady(prepareShell: true);
      readiness.resetForTesting();

      expect(readiness.shellPrepComplete, isFalse);
      expect(readiness.recitersDataReady, isFalse);
      expect(readiness.timedOut, isFalse);
    });
  });
}
