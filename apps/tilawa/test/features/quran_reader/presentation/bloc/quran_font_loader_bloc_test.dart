import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/check_fonts_downloaded_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/download_quran_fonts_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/load_quran_fonts_to_engine_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/update_current_page_use_case.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_font_loader_bloc.dart';

class MockCheckFontsDownloadedUseCase extends Mock
    implements CheckFontsDownloadedUseCase {}

class MockDownloadQuranFontsUseCase extends Mock
    implements DownloadQuranFontsUseCase {}

class MockLoadQuranFontsToEngineUseCase extends Mock
    implements LoadQuranFontsToEngineUseCase {}

class MockUpdateCurrentPageUseCase extends Mock
    implements UpdateCurrentPageUseCase {}

void main() {
  late MockCheckFontsDownloadedUseCase mockCheckFontsDownloadedUseCase;
  late MockDownloadQuranFontsUseCase mockDownloadQuranFontsUseCase;
  late MockLoadQuranFontsToEngineUseCase mockLoadQuranFontsToEngineUseCase;
  late MockUpdateCurrentPageUseCase mockUpdateCurrentPageUseCase;
  late QuranFontLoaderBloc bloc;

  setUp(() {
    mockCheckFontsDownloadedUseCase = MockCheckFontsDownloadedUseCase();
    mockDownloadQuranFontsUseCase = MockDownloadQuranFontsUseCase();
    mockLoadQuranFontsToEngineUseCase = MockLoadQuranFontsToEngineUseCase();
    mockUpdateCurrentPageUseCase = MockUpdateCurrentPageUseCase();

    bloc = QuranFontLoaderBloc(
      mockCheckFontsDownloadedUseCase,
      mockDownloadQuranFontsUseCase,
      mockLoadQuranFontsToEngineUseCase,
      mockUpdateCurrentPageUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('QuranFontLoaderBloc Throttling', () {
    blocTest<QuranFontLoaderBloc, QuranFontLoaderState>(
      'should throttle progress updates to 1% increments',
      build: () {
        when(
          () => mockLoadQuranFontsToEngineUseCase.isFontLoaded(any()),
        ).thenReturn(false);
        when(
          () => mockCheckFontsDownloadedUseCase(),
        ).thenAnswer((_) async => false);
        when(
          () => mockLoadQuranFontsToEngineUseCase.ensureFontReady(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLoadQuranFontsToEngineUseCase.ensureQuranDataLoaded(),
        ).thenAnswer((_) async {});
        when(
          () => mockLoadQuranFontsToEngineUseCase.warmInitialPage(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLoadQuranFontsToEngineUseCase.batchWarmPages(
            start: any(named: 'start'),
            end: any(named: 'end'),
            pivotPage: any(named: 'pivotPage'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async {});

        when(
          () => mockDownloadQuranFontsUseCase(
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((invocation) async {
          final onProgress =
              invocation.namedArguments[#onProgress] as void Function(double)?;
          if (onProgress != null) {
            // Emitting updates with small increments
            onProgress(0.001); // Throttled
            onProgress(0.005); // Throttled
            onProgress(0.01); // Emitted
            onProgress(0.015); // Throttled
            onProgress(0.019); // Throttled
            onProgress(0.02); // Emitted
            onProgress(0.99); // Emitted
            onProgress(0.995); // Throttled
            onProgress(1.0); // Emitted
          }
        });
        return bloc;
      },
      act: (bloc) => bloc.add(
        const QuranFontLoaderEvent.initialize(initialPageNumber: 118),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const QuranFontLoaderState.checking(),
        const QuranFontLoaderState.downloading(0),
        const QuranFontLoaderState.downloading(0.01),
        const QuranFontLoaderState.downloading(0.02),
        const QuranFontLoaderState.downloading(0.99),
        const QuranFontLoaderState.downloading(1.0),
        const QuranFontLoaderState.registering(),
        const QuranFontLoaderState.success(),
      ],
      verify: (_) {
        verifyNever(
          () => mockLoadQuranFontsToEngineUseCase.warmInitialPage(any()),
        );
        verifyNever(
          () => mockLoadQuranFontsToEngineUseCase.batchWarmPages(
            start: any(named: 'start'),
            end: any(named: 'end'),
            pivotPage: any(named: 'pivotPage'),
            onProgress: any(named: 'onProgress'),
          ),
        );
      },
    );
  });
}
