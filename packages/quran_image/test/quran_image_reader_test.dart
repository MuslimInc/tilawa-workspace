import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/data/repositories/in_memory_navigation_visibility_repository.dart';
import 'package:quran_image/data/repositories/in_memory_page_repository.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/l10n/quran_image_localizations.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';
import 'package:quran_image/presentation/widgets/organisms/navigation_slider_overlay.dart';
import 'package:quran_image/quran_image_reader.dart';

import 'seeded_navigation_bloc.dart';

Future<void> _pumpReaderHarness(
  WidgetTester tester,
  NavigationBloc navigationBloc,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: QuranImageLocalizations.localizationsDelegates,
      supportedLocales: QuranImageLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<NavigationBloc>.value(
        value: navigationBloc,
        child: const QuranImageReader(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _showNavigationSlider(
  WidgetTester tester,
  NavigationBloc navigationBloc,
) async {
  emitTestNavigationVisibility(navigationBloc, isVisible: true);
  await tester.pump();
  // [AnimatedBuilder] sets [IgnorePointer] while the slide animation is at 0.
  await tester.pumpAndSettle(const Duration(seconds: 3));
  expect(find.byType(NavigationSliderOverlay), findsOneWidget);
}

Future<void> _pumpUntilNavigationSettles(
  WidgetTester tester, {
  int maxPumps = 80,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late _TestQuranImageCacheRepository imageRepository;
  late _TestQuranImagePrewarmer imagePrewarmer;
  late SeededNavigationBloc navigationBloc;

  setUp(() async {
    await sl.reset();

    tempDirectory = await Directory.systemTemp.createTemp(
      'quran_image_reader_test_',
    );
    const transparentPixel =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg==';
    final bytes = base64Decode(transparentPixel);
    final linePaths = <int, String>{};
    for (var line = 1; line <= 15; line++) {
      final file = File('${tempDirectory.path}/line_$line.png');
      await file.writeAsBytes(bytes);
      linePaths[line] = file.path;
    }

    imageRepository = _TestQuranImageCacheRepository(linePaths);
    imagePrewarmer = _TestQuranImagePrewarmer();
    navigationBloc = SeededNavigationBloc(
      initialState: NavigationLoaded(
        pageState: PageState.initial(),
        visibility: NavigationVisibility.initial(),
      ),
      pageRepository: InMemoryPageRepository(),
      visibilityRepository: InMemoryNavigationVisibilityRepository(),
      saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
        _InMemoryLastVisitedPageRepository(),
      ),
      getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
        _InMemoryLastVisitedPageRepository(initialPage: 1),
      ),
    );

    sl.registerLazySingleton<QuranImagePrewarmer>(() => imagePrewarmer);
    sl.registerLazySingleton<QuranImageCacheRepository>(() => imageRepository);
    sl.registerLazySingleton<VerseMarkerRepository>(
      () => _EmptyVerseMarkerRepository(),
    );
    sl.registerLazySingleton<SurahHeaderRepository>(
      () => _EmptySurahHeaderRepository(),
    );
    sl.registerLazySingleton<DecodedQuranImageCache>(
      _ReaderTestDecodedQuranImageCache.new,
    );
  });

  tearDown(() async {
    await navigationBloc.close();
    await sl.reset();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets(
    'reader starts prewarm, toggles navigation, and handles lifecycle',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              QuranImageLocalizations.localizationsDelegates,
          supportedLocales: QuranImageLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: BlocProvider<NavigationBloc>.value(
            value: navigationBloc,
            child: const QuranImageReader(),
          ),
        ),
      );
      await tester.pump();

      expect(imagePrewarmer.startInitialRequests, hasLength(1));
      expect(imagePrewarmer.startInitialRequests.single.pageNumber, 1);

      emitTestNavigationVisibility(navigationBloc, isVisible: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(NavigationSliderOverlay), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleMemoryPressure();
      await tester.pump();
      expect(imagePrewarmer.memoryPressureCount, 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(imagePrewarmer.currentTargetRequests, isNotEmpty);

      tester.binding.handleMemoryPressure();
      await tester.pump();
      expect(imagePrewarmer.memoryPressureCount, 1);
      expect(imagePrewarmer.cancelCount, greaterThanOrEqualTo(1));
    },
  );

  testWidgets('reader responds to swipe navigation and schedules warmup work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: QuranImageLocalizations.localizationsDelegates,
        supportedLocales: QuranImageLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<NavigationBloc>.value(
          value: navigationBloc,
          child: const QuranImageReader(),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect((navigationBloc.state as NavigationLoaded).pageState.currentPage, 2);
    expect(
      imagePrewarmer.currentTargetRequests
          .map((request) => request.pageNumber)
          .any((page) => page >= 2),
      isTrue,
    );
    expect(
      imagePrewarmer.settledWindowRequests.map((request) => request.pageNumber),
      contains(2),
    );

    await tester.pump(const Duration(milliseconds: 800));
    expect(imagePrewarmer.disposeCount, 0);
  });

  /// Regression: [PageSlider] local drag value under RTL + nav overlay.
  /// Full jump policy table: [reader_slider_jump_policy_test.dart].
  group('QuranImageReader slider', () {
    testWidgets('slider thumb moves during drag before page commits', (
      tester,
    ) async {
      await _pumpReaderHarness(tester, navigationBloc);
      await _showNavigationSlider(tester, navigationBloc);

      final slider = find.byType(Slider);
      final rect = tester.getRect(slider);
      final gesture = await tester.startGesture(
        Offset(rect.right - 12, rect.center.dy),
      );
      await gesture.moveBy(const Offset(-220, 0));
      await tester.pump();

      expect(tester.widget<Slider>(slider).value, greaterThan(5));
      expect(
        (navigationBloc.state as NavigationLoaded).pageState.currentPage,
        1,
      );

      await gesture.up();
      await _pumpUntilNavigationSettles(tester);
    });

    testWidgets(
      'long jump queries verse markers while page decode is in flight',
      (tester) async {
        final markerRepository = _TrackingVerseMarkerRepository(
          markersByPage: {
            20: const [
              VerseMarkerData(sura: 1, ayah: 1, line: 0, centerX: 0.5),
              VerseMarkerData(sura: 1, ayah: 2, line: 1, centerX: 0.6),
            ],
          },
        );
        final ensurePageReadyGate = Completer<void>();
        final blockingPrewarmer = _BlockingTestQuranImagePrewarmer(
          ensurePageReadyGate,
        );

        await sl.reset();
        sl.registerLazySingleton<QuranImagePrewarmer>(() => blockingPrewarmer);
        sl.registerLazySingleton<QuranImageCacheRepository>(
          () => imageRepository,
        );
        sl.registerLazySingleton<VerseMarkerRepository>(
          () => markerRepository,
        );
        sl.registerLazySingleton<SurahHeaderRepository>(
          () => _EmptySurahHeaderRepository(),
        );
        sl.registerLazySingleton<DecodedQuranImageCache>(
          _ReaderTestDecodedQuranImageCache.new,
        );

        await _pumpReaderHarness(tester, navigationBloc);
        await _showNavigationSlider(tester, navigationBloc);

        final slider = find.byType(Slider);
        final rect = tester.getRect(slider);
        final gesture = await tester.startGesture(
          Offset(rect.center.dx, rect.center.dy),
        );
        await gesture.moveBy(const Offset(-180, 0));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 50));
        expect(blockingPrewarmer.jumpTargetRequests, isNotEmpty);
        expect(
          blockingPrewarmer.jumpTargetRequests.last.pageNumber,
          greaterThan(3),
        );
        expect(blockingPrewarmer.ensurePageReadyRequests, isNotEmpty);
        expect(
          markerRepository.queriedPages,
          contains(blockingPrewarmer.ensurePageReadyRequests.last.pageNumber),
        );

        ensurePageReadyGate.complete();
        await _pumpUntilNavigationSettles(tester);
      },
    );
  });
}

class _TestQuranImagePrewarmer implements QuranImagePrewarmer {
  final List<_WarmRequest> startInitialRequests = <_WarmRequest>[];
  final List<_WarmRequest> currentTargetRequests = <_WarmRequest>[];
  final List<_WarmRequest> previewTargetRequests = <_WarmRequest>[];
  final List<_WarmRequest> jumpTargetRequests = <_WarmRequest>[];
  final List<_WarmRequest> ensurePageReadyRequests = <_WarmRequest>[];
  final List<_WarmRequest> settledWindowRequests = <_WarmRequest>[];
  int cancelCount = 0;
  int memoryPressureCount = 0;
  int disposeCount = 0;

  @override
  void cancel() {
    cancelCount++;
  }

  @override
  void dispose() {
    disposeCount++;
  }

  @override
  Future<void> ensurePageReady({
    required int pageNumber,
    required int cacheWidth,
  }) async {
    ensurePageReadyRequests.add(
      _WarmRequest(pageNumber: pageNumber, cacheWidth: cacheWidth),
    );
  }

  @override
  void handleMemoryPressure() {
    memoryPressureCount++;
  }

  @override
  void prewarmCurrentTarget({
    required int pageNumber,
    required int cacheWidth,
  }) {
    currentTargetRequests.add(
      _WarmRequest(pageNumber: pageNumber, cacheWidth: cacheWidth),
    );
  }

  @override
  void prewarmJumpTarget({required int pageNumber, required int cacheWidth}) {
    jumpTargetRequests.add(
      _WarmRequest(pageNumber: pageNumber, cacheWidth: cacheWidth),
    );
  }

  @override
  void prewarmPreviewTarget({
    required int pageNumber,
    required int cacheWidth,
  }) {
    previewTargetRequests.add(
      _WarmRequest(pageNumber: pageNumber, cacheWidth: cacheWidth),
    );
  }

  @override
  void prewarmSettledWindow({
    required int pageNumber,
    required int cacheWidth,
    int radius = 1,
  }) {
    settledWindowRequests.add(
      _WarmRequest(pageNumber: pageNumber, cacheWidth: cacheWidth),
    );
  }

  @override
  void startInitialPrewarm({
    required int currentPageNumber,
    required int cacheWidth,
  }) {
    startInitialRequests.add(
      _WarmRequest(pageNumber: currentPageNumber, cacheWidth: cacheWidth),
    );
  }
}

class _BlockingTestQuranImagePrewarmer extends _TestQuranImagePrewarmer {
  _BlockingTestQuranImagePrewarmer(this._ensurePageReadyGate);

  final Completer<void> _ensurePageReadyGate;

  @override
  Future<void> ensurePageReady({
    required int pageNumber,
    required int cacheWidth,
  }) async {
    ensurePageReadyRequests.add(
      _WarmRequest(pageNumber: pageNumber, cacheWidth: cacheWidth),
    );
    await _ensurePageReadyGate.future;
  }
}

class _WarmRequest {
  const _WarmRequest({required this.pageNumber, required this.cacheWidth});

  final int pageNumber;
  final int cacheWidth;
}

class _TrackingVerseMarkerRepository implements VerseMarkerRepository {
  _TrackingVerseMarkerRepository({required this.markersByPage});

  final Map<int, List<VerseMarkerData>> markersByPage;
  final List<int> queriedPages = <int>[];

  @override
  bool get isDebugMode => false;

  @override
  bool get isPreloaded => true;

  @override
  bool get isPreloading => false;

  @override
  double get preloadProgress => 1;

  @override
  void dispose() {}

  @override
  List<VerseMarkerData> getMarkersForPage(int pageNumber) {
    queriedPages.add(pageNumber);
    return markersByPage[pageNumber] ?? const <VerseMarkerData>[];
  }

  @override
  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber) async =>
      getMarkersForPage(pageNumber);
}

class _TestQuranImageCacheRepository implements QuranImageCacheRepository {
  _TestQuranImageCacheRepository(this.linePaths);

  final Map<int, String> linePaths;

  @override
  QuranImageCacheStatus get status => const QuranImageCacheStatus.ready();

  @override
  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) {
    return linePaths[oneBasedLineNumber];
  }

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    const status = QuranImageCacheStatus.ready();
    onProgress?.call(status);
    return status;
  }

  @override
  String? surahHeaderBannerFilePath() => null;
}

class _EmptyVerseMarkerRepository implements VerseMarkerRepository {
  @override
  bool get isDebugMode => false;

  @override
  bool get isPreloaded => true;

  @override
  bool get isPreloading => false;

  @override
  double get preloadProgress => 1;

  @override
  void dispose() {}

  @override
  List<VerseMarkerData> getMarkersForPage(int pageNumber) =>
      const <VerseMarkerData>[];

  @override
  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber) async =>
      const <VerseMarkerData>[];
}

class _EmptySurahHeaderRepository implements SurahHeaderRepository {
  @override
  List<SurahHeaderData> getHeadersForPage(int pageNumber) =>
      const <SurahHeaderData>[];
}

class _InMemoryLastVisitedPageRepository implements LastVisitedPageRepository {
  _InMemoryLastVisitedPageRepository({this.initialPage});

  final int? initialPage;
  int? _page;

  @override
  Future<void> clearLastVisitedPage() async {
    _page = null;
  }

  @override
  Future<int?> getLastVisitedPage() async => _page ?? initialPage;

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {
    _page = pageNumber;
  }
}

class _ReaderTestDecodedQuranImageCache implements DecodedQuranImageCache {
  @override
  void handleMemoryPressure() {}

  @override
  ImageProvider<Object> fileImageProvider({required String imagePath}) {
    return MemoryImage(Uint8List(0));
  }

  @override
  ImageProvider<Object> lineImageProvider({
    required String imagePath,
    required int cacheWidth,
  }) {
    return MemoryImage(Uint8List(0));
  }

  @override
  Future<void> prewarmFileImage(String imagePath) async {}

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) async {}
}
