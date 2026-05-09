import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/l10n/app_localizations.dart';
import 'package:quran_image/preloading_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('completes preload and prewarms the initial page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final markerRepository = _TestAssetVerseMarkerRepository(
      markersByPage: <int, List<VerseMarkerData>>{
        5: const <VerseMarkerData>[
          VerseMarkerData(sura: 1, ayah: 1, line: 0, centerX: 0.4),
          VerseMarkerData(sura: 1, ayah: 2, line: 1, centerX: 0.6),
        ],
        6: const <VerseMarkerData>[
          VerseMarkerData(sura: 2, ayah: 255, line: 5, centerX: 0.5),
        ],
      },
    );
    final imageRepository = _TestQuranImageCacheRepository(
      linePathsByPage: <int, Map<int, String>>{
        5: <int, String>{
          for (var line = 1; line <= 15; line++)
            line: '/tmp/page5_line$line.png',
        },
      },
      prepareStatuses: const <QuranImageCacheStatus>[
        QuranImageCacheStatus(
          phase: QuranImageCachePhase.extracting,
          progress: 0.7,
        ),
      ],
      finalStatus: const QuranImageCacheStatus.ready(),
    );
    final decodedCache = _TestDecodedQuranImageCache();
    final lastVisitedRepository = _InMemoryLastVisitedPageRepository(5);
    await _registerDependencies(
      markerRepository: markerRepository,
      imageRepository: imageRepository,
      decodedCache: decodedCache,
      lastVisitedRepository: lastVisitedRepository,
    );

    var preloadCompleteCount = 0;
    await tester.pumpWidget(
      _buildHarness(
        PreloadingScreen(onPreloadComplete: () => preloadCompleteCount++),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(preloadCompleteCount, 1);
    expect(decodedCache.lineWarmups, hasLength(15));
    expect(
      decodedCache.lineWarmups.every((request) => request.cacheWidth == 1080),
      isTrue,
    );
    expect(markerRepository.requestedPages, containsAll(const <int>[5, 6]));
  });

  testWidgets('shows an error and retries after cache preparation failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final markerRepository = _TestAssetVerseMarkerRepository(
      isInitializedValue: true,
    );
    final imageRepository = _TestQuranImageCacheRepository(
      linePathsByPage: const <int, Map<int, String>>{},
      finalStatuses: <QuranImageCacheStatus>[
        const QuranImageCacheStatus.failed('SocketException: down'),
        const QuranImageCacheStatus.ready(),
      ],
    );
    final decodedCache = _TestDecodedQuranImageCache();
    await _registerDependencies(
      markerRepository: markerRepository,
      imageRepository: imageRepository,
      decodedCache: decodedCache,
      lastVisitedRepository: _InMemoryLastVisitedPageRepository(1),
    );

    var preloadCompleteCount = 0;
    await tester.pumpWidget(
      _buildHarness(
        PreloadingScreen(onPreloadComplete: () => preloadCompleteCount++),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      find.text('Please check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(preloadCompleteCount, 0);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(preloadCompleteCount, 1);
  });

  testWidgets('shows an error when marker initialization fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final markerRepository = _TestAssetVerseMarkerRepository(
      initError: StateError('marker init failed'),
    );
    final imageRepository = _TestQuranImageCacheRepository(
      linePathsByPage: const <int, Map<int, String>>{},
      finalStatus: const QuranImageCacheStatus.ready(),
    );
    await _registerDependencies(
      markerRepository: markerRepository,
      imageRepository: imageRepository,
      decodedCache: _TestDecodedQuranImageCache(),
      lastVisitedRepository: _InMemoryLastVisitedPageRepository(1),
    );

    await tester.pumpWidget(
      _buildHarness(const PreloadingScreen(onPreloadComplete: _noop)),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}

Widget _buildHarness(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Future<void> _registerDependencies({
  required _TestAssetVerseMarkerRepository markerRepository,
  required _TestQuranImageCacheRepository imageRepository,
  required _TestDecodedQuranImageCache decodedCache,
  required _InMemoryLastVisitedPageRepository lastVisitedRepository,
}) async {
  sl.registerLazySingleton<AssetVerseMarkerRepository>(() => markerRepository);
  sl.registerLazySingleton<QuranImageCacheRepository>(() => imageRepository);
  sl.registerLazySingleton<DecodedQuranImageCache>(() => decodedCache);
  sl.registerLazySingleton<GetLastVisitedPageUseCase>(
    () => GetLastVisitedPageUseCase(lastVisitedRepository),
  );
  sl.registerLazySingleton<PrepareQuranImageCacheUseCase>(
    () => PrepareQuranImageCacheUseCase(imageRepository),
  );
}

void _noop() {}

class _InMemoryLastVisitedPageRepository implements LastVisitedPageRepository {
  _InMemoryLastVisitedPageRepository(this._page);

  int? _page;

  @override
  Future<void> clearLastVisitedPage() async {
    _page = null;
  }

  @override
  Future<int?> getLastVisitedPage() async => _page;

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {
    _page = pageNumber;
  }
}

class _TestQuranImageCacheRepository implements QuranImageCacheRepository {
  _TestQuranImageCacheRepository({
    required this.linePathsByPage,
    this.prepareStatuses = const <QuranImageCacheStatus>[],
    this.finalStatus = const QuranImageCacheStatus.ready(),
    List<QuranImageCacheStatus>? finalStatuses,
  }) : _finalStatuses = finalStatuses;

  final Map<int, Map<int, String>> linePathsByPage;
  final List<QuranImageCacheStatus> prepareStatuses;
  final QuranImageCacheStatus finalStatus;
  final List<QuranImageCacheStatus>? _finalStatuses;
  int _prepareCallCount = 0;
  QuranImageCacheStatus _status = const QuranImageCacheStatus.checking();

  @override
  QuranImageCacheStatus get status => _status;

  @override
  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) {
    return linePathsByPage[pageNumber]?[oneBasedLineNumber];
  }

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    for (final status in prepareStatuses) {
      _status = status;
      onProgress?.call(status);
    }

    final statuses = _finalStatuses;
    final result = statuses == null
        ? finalStatus
        : statuses[_prepareCallCount.clamp(0, statuses.length - 1)];
    _prepareCallCount++;
    _status = result;
    onProgress?.call(result);
    return result;
  }

  @override
  String? surahHeaderBannerFilePath() => null;
}

class _LineWarmupRequest {
  const _LineWarmupRequest({required this.imagePath, required this.cacheWidth});

  final String imagePath;
  final int cacheWidth;
}

class _TestDecodedQuranImageCache implements DecodedQuranImageCache {
  final List<_LineWarmupRequest> lineWarmups = <_LineWarmupRequest>[];

  @override
  void handleMemoryPressure() {}

  @override
  Future<void> prewarmFileImage(String imagePath) async {}

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) async {
    lineWarmups.add(
      _LineWarmupRequest(imagePath: imagePath, cacheWidth: cacheWidth),
    );
  }
}

class _TestAssetVerseMarkerRepository extends AssetVerseMarkerRepository {
  _TestAssetVerseMarkerRepository({
    this.isInitializedValue = false,
    this.initError,
    Map<int, List<VerseMarkerData>>? markersByPage,
  }) : _markersByPage = markersByPage ?? <int, List<VerseMarkerData>>{};

  final bool isInitializedValue;
  final Object? initError;
  final Map<int, List<VerseMarkerData>> _markersByPage;
  final List<int> requestedPages = <int>[];
  bool _initialized = false;

  @override
  bool get isDebugMode => false;

  @override
  bool get isInitialized => isInitializedValue || _initialized;

  @override
  bool get isPreloaded => preloadProgress >= 1.0;

  @override
  bool get isPreloading => false;

  @override
  double get preloadProgress => 1.0;

  @override
  List<VerseMarkerData> getMarkersForPage(int pageNumber) {
    requestedPages.add(pageNumber);
    return _markersByPage[pageNumber] ?? const <VerseMarkerData>[];
  }

  @override
  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber) async =>
      getMarkersForPage(pageNumber);

  @override
  Future<void> init({
    bool forceDebugSource = false,
    bool? preloadAllPages,
  }) async {
    final error = initError;
    if (error != null) {
      if (error is Error) throw error;
      if (error is Exception) throw error;
      throw StateError('$error');
    }
    _initialized = true;
  }
}
