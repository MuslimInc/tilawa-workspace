import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/usecases.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/settings/quran_settings_bloc.dart';

import '../../../../../helpers/hydrated_bloc_test_helper.dart';

class MockLoadReaderSettingsUseCase extends Mock
    implements LoadReaderSettingsUseCase {}

class MockSaveReaderSettingsUseCase extends Mock
    implements SaveReaderSettingsUseCase {}

void main() {
  late MockLoadReaderSettingsUseCase loadReaderSettingsUseCase;
  late MockSaveReaderSettingsUseCase saveReaderSettingsUseCase;
  late QuranSettingsBloc bloc;

  setUpAll(() async {
    await initializeHydratedStorageForTest();
    registerFallbackValue(const ReaderSettingsEntity());
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  setUp(() {
    loadReaderSettingsUseCase = MockLoadReaderSettingsUseCase();
    saveReaderSettingsUseCase = MockSaveReaderSettingsUseCase();

    bloc = QuranSettingsBloc(
      loadReaderSettingsUseCase,
      saveReaderSettingsUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('QuranSettingsBloc', () {
    test('initial state should be valid', () {
      expect(bloc.state.isLoading, false);
      expect(bloc.state.errorMessage, null);
    });

    group('loadSettings', () {
      blocTest<QuranSettingsBloc, QuranSettingsState>(
        'emits [isLoading=true, settings=loaded, isLoading=false] when successful',
        build: () {
          when(() => loadReaderSettingsUseCase.call()).thenAnswer(
            (_) async => const Right(ReaderSettingsEntity(fontSize: 30.0)),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranSettingsEvent.loadSettings()),
        expect: () => [
          const QuranSettingsState(isLoading: true),
          const QuranSettingsState(
            settings: ReaderSettingsEntity(fontSize: 30.0),
          ),
        ],
      );

      blocTest<QuranSettingsBloc, QuranSettingsState>(
        'emits [isLoading=true, errorMessage=failure, isLoading=false] when failure',
        build: () {
          when(
            () => loadReaderSettingsUseCase.call(),
          ).thenAnswer((_) async => const Left(UnexpectedFailure('error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranSettingsEvent.loadSettings()),
        expect: () => [
          const QuranSettingsState(isLoading: true),
          const QuranSettingsState(errorMessage: 'UnexpectedFailure(error)'),
        ],
      );
    });

    group('updateFontSize', () {
      blocTest<QuranSettingsBloc, QuranSettingsState>(
        'emits updated settings and calls save use case',
        build: () {
          when(
            () => saveReaderSettingsUseCase.call(
              settings: any(named: 'settings'),
            ),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranSettingsEvent.updateFontSize(28.0)),
        expect: () => [
          const QuranSettingsState(
            settings: ReaderSettingsEntity(fontSize: 28.0),
          ),
        ],
        verify: (_) {
          verify(
            () => saveReaderSettingsUseCase.call(
              settings: const ReaderSettingsEntity(fontSize: 28.0),
            ),
          ).called(1);
        },
      );
    });

    group('toggleTranslation', () {
      blocTest<QuranSettingsBloc, QuranSettingsState>(
        'emits updated settings and calls save use case',
        build: () {
          when(
            () => saveReaderSettingsUseCase.call(
              settings: any(named: 'settings'),
            ),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranSettingsEvent.toggleTranslation()),
        expect: () => [
          const QuranSettingsState(
            settings: ReaderSettingsEntity(showTranslation: false),
          ),
        ],
        verify: (_) {
          verify(
            () => saveReaderSettingsUseCase.call(
              settings: const ReaderSettingsEntity(showTranslation: false),
            ),
          ).called(1);
        },
      );
    });

    group('updateSettings', () {
      blocTest<QuranSettingsBloc, QuranSettingsState>(
        'emits updated settings and calls save use case',
        build: () {
          when(
            () => saveReaderSettingsUseCase.call(
              settings: any(named: 'settings'),
            ),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const QuranSettingsEvent.updateSettings(
            ReaderSettingsEntity(fontSize: 40.0),
          ),
        ),
        expect: () => [
          const QuranSettingsState(
            settings: ReaderSettingsEntity(fontSize: 40.0),
          ),
        ],
        verify: (_) {
          verify(
            () => saveReaderSettingsUseCase.call(
              settings: const ReaderSettingsEntity(fontSize: 40.0),
            ),
          ).called(1);
        },
      );
    });
  });
}
