import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'app_startup_readiness_test.mocks.dart';

@GenerateMocks([GetRecitersUseCase])
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
  late RecitersBloc recitersBloc;
  late MockGetRecitersUseCase mockGetReciters;

  setUp(() {
    mockGetReciters = MockGetRecitersUseCase();
    recitersBloc = RecitersBloc(mockGetReciters);
    readiness = AppStartupReadiness(recitersBloc);
  });

  tearDown(() async {
    await recitersBloc.close();
  });

  group('waitUntilReady(prepareShell: false)', () {
    test('does not touch reciters or shell flags', () async {
      await readiness.waitUntilReady(prepareShell: false);

      expect(readiness.shellPrepComplete, isFalse);
      expect(readiness.recitersDataReady, isFalse);
      expect(readiness.timedOut, isFalse);
      verifyNever(mockGetReciters.call());
    });
  });

  group('waitUntilReady(prepareShell: true)', () {
    test('preloads reciters and marks shell prep complete', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async =>
            const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
      );

      await readiness.waitUntilReady(prepareShell: true);

      expect(readiness.shellPrepComplete, isTrue);
      expect(readiness.recitersDataReady, isTrue);
      expect(readiness.timedOut, isFalse);
      expect(recitersBloc.state, isA<RecitersLoaded>());
      verify(mockGetReciters.call()).called(1);
    });

    test('skips fetch when bloc is already RecitersLoaded', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async => const Right<Failure, List<ReciterEntity>>([
          sampleReciter,
        ]),
      );
      recitersBloc.add(const LoadReciters());
      await recitersBloc.stream.firstWhere((s) => s is RecitersLoaded);

      await readiness.waitUntilReady(prepareShell: true);

      expect(readiness.recitersDataReady, isTrue);
      verify(mockGetReciters.call()).called(1);
    });

    test('waits for in-flight load without dispatching LoadReciters again', () async {
      final completer = Completer<Either<Failure, List<ReciterEntity>>>();
      when(mockGetReciters.call()).thenAnswer((_) => completer.future);

      recitersBloc.add(const LoadReciters());
      await recitersBloc.stream.firstWhere((s) => s is RecitersLoading);

      final Future<void> prep = readiness.waitUntilReady(prepareShell: true);
      verify(mockGetReciters.call()).called(1);

      completer.complete(
        const Right<Failure, List<ReciterEntity>>([sampleReciter]),
      );
      await prep;

      expect(readiness.recitersDataReady, isTrue);
      expect(readiness.shellPrepComplete, isTrue);
    });

    test('sets recitersDataReady false when fetch ends in error state', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async => Left<Failure, List<ReciterEntity>>(
          UnexpectedFailure('network'),
        ),
      );

      await readiness.waitUntilReady(prepareShell: true);

      expect(readiness.shellPrepComplete, isTrue);
      expect(readiness.recitersDataReady, isFalse);
      expect(recitersBloc.state, isA<RecitersError>());
    });

    test('second call is a no-op after success', () async {
      when(mockGetReciters.call()).thenAnswer(
        (_) async =>
            const Right<Failure, List<ReciterEntity>>(<ReciterEntity>[]),
      );
      await readiness.waitUntilReady(prepareShell: true);
      await readiness.waitUntilReady(prepareShell: true);

      verify(mockGetReciters.call()).called(1);
    });

    test('times out and still allows navigation flags', () {
      fakeAsync((FakeAsync async) {
        when(mockGetReciters.call()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(seconds: 30));
          return const Right<Failure, List<ReciterEntity>>([]);
        });

        var completed = false;
        readiness
            .waitUntilReady(prepareShell: true)
            .then((_) => completed = true);

        async.elapse(AppStartupReadiness.maxSplashDuration);
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(readiness.timedOut, isTrue);
        expect(readiness.shellPrepComplete, isTrue);
      });
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
