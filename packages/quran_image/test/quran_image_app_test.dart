import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/quran_image_app.dart';
import 'package:quran_image/quran_image_reader.dart';

void main() {
  late Directory tempDirectory;
  late String headerPath;

  setUp(() async {
    await sl.reset();
    await initDependencies();

    tempDirectory = await Directory.systemTemp.createTemp(
      'quran_image_app_test_',
    );
    headerPath = '${tempDirectory.path}/sura_header_banner.webp';
    await File(headerPath).writeAsBytes([0x52, 0x49, 0x46, 0x46]);
  });

  tearDown(() async {
    await sl.reset();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('shows retry UI on navigation init failure and recovers', (
    tester,
  ) async {
    await sl.unregister<LastVisitedPageRepository>();
    final flakyRepository = _FlakyLastVisitedPageRepository();
    sl.registerLazySingleton<LastVisitedPageRepository>(() => flakyRepository);
    await sl.unregister<GetLastVisitedPageUseCase>();
    sl.registerLazySingleton<GetLastVisitedPageUseCase>(
      () => GetLastVisitedPageUseCase(flakyRepository),
    );
    await sl.unregister<SaveLastVisitedPageUseCase>();
    sl.registerLazySingleton<SaveLastVisitedPageUseCase>(
      () => SaveLastVisitedPageUseCase(flakyRepository),
    );
    await sl.unregister<QuranImageCacheRepository>();
    sl.registerLazySingleton<QuranImageCacheRepository>(
      () => _ReadyQuranImageCacheRepository(headerPath),
    );
    await sl.unregister<AssetVerseMarkerRepository>();
    final markerRepository = _ReadyAssetVerseMarkerRepository();
    sl.registerLazySingleton<AssetVerseMarkerRepository>(
      () => markerRepository,
    );
    await sl.unregister<VerseMarkerRepository>();
    sl.registerLazySingleton<VerseMarkerRepository>(() => markerRepository);

    await tester.pumpWidget(const QuranImageApp());
    await tester.pumpAndSettle();

    expect(find.text('حدث خطأ ما. يرجى المحاولة مرة أخرى.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.byType(QuranImageReader), findsOneWidget);
  });

  testWidgets('runs through the preload screen when cache is not ready yet', (
    tester,
  ) async {
    await sl.unregister<LastVisitedPageRepository>();
    final lastVisitedRepository = _FlakyLastVisitedPageRepository(
      failGetCount: 0,
      initialPage: 1,
    );
    sl.registerLazySingleton<LastVisitedPageRepository>(
      () => lastVisitedRepository,
    );
    await sl.unregister<GetLastVisitedPageUseCase>();
    sl.registerLazySingleton<GetLastVisitedPageUseCase>(
      () => GetLastVisitedPageUseCase(lastVisitedRepository),
    );
    await sl.unregister<SaveLastVisitedPageUseCase>();
    sl.registerLazySingleton<SaveLastVisitedPageUseCase>(
      () => SaveLastVisitedPageUseCase(lastVisitedRepository),
    );
    await sl.unregister<QuranImageCacheRepository>();
    sl.registerLazySingleton<QuranImageCacheRepository>(
      () => _PreloadingQuranImageCacheRepository(headerPath),
    );
    await sl.unregister<PrepareQuranImageCacheUseCase>();
    sl.registerLazySingleton<PrepareQuranImageCacheUseCase>(
      () => PrepareQuranImageCacheUseCase(sl<QuranImageCacheRepository>()),
    );
    await sl.unregister<AssetVerseMarkerRepository>();
    final markerRepository = _LazyAssetVerseMarkerRepository();
    sl.registerLazySingleton<AssetVerseMarkerRepository>(
      () => markerRepository,
    );
    await sl.unregister<VerseMarkerRepository>();
    sl.registerLazySingleton<VerseMarkerRepository>(() => markerRepository);

    await tester.pumpWidget(const QuranImageApp());
    await tester.pump();

    expect(find.text('القرآن'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(QuranImageReader), findsOneWidget);
  });
}

class _ReadyQuranImageCacheRepository implements QuranImageCacheRepository {
  const _ReadyQuranImageCacheRepository(this._headerPath);

  final String _headerPath;

  @override
  QuranImageCacheStatus get status => const QuranImageCacheStatus.ready();

  @override
  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) => null;

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    const status = QuranImageCacheStatus.ready();
    onProgress?.call(status);
    return status;
  }

  @override
  String? surahHeaderBannerFilePath() => _headerPath;
}

class _PreloadingQuranImageCacheRepository
    extends _ReadyQuranImageCacheRepository {
  _PreloadingQuranImageCacheRepository(super.headerPath);

  QuranImageCacheStatus _status = const QuranImageCacheStatus.checking();

  @override
  QuranImageCacheStatus get status => _status;

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    const progress = QuranImageCacheStatus(
      phase: QuranImageCachePhase.extracting,
      progress: 0.6,
    );
    _status = progress;
    onProgress?.call(progress);
    _status = const QuranImageCacheStatus.ready();
    onProgress?.call(_status);
    return _status;
  }
}

class _ReadyAssetVerseMarkerRepository extends AssetVerseMarkerRepository {
  @override
  bool get isInitialized => true;

  @override
  bool get isDebugMode => false;

  @override
  bool get isPreloaded => true;

  @override
  bool get isPreloading => false;

  @override
  double get preloadProgress => 1;

  @override
  List<VerseMarkerData> getMarkersForPage(int pageNumber) =>
      const <VerseMarkerData>[];

  @override
  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber) async =>
      const <VerseMarkerData>[];

  @override
  Future<void> init({
    bool forceDebugSource = false,
    bool? preloadAllPages,
  }) async {}
}

class _LazyAssetVerseMarkerRepository extends _ReadyAssetVerseMarkerRepository {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> init({
    bool forceDebugSource = false,
    bool? preloadAllPages,
  }) async {
    _initialized = true;
  }
}

class _FlakyLastVisitedPageRepository implements LastVisitedPageRepository {
  _FlakyLastVisitedPageRepository({
    this.failGetCount = 1,
    this.initialPage = 1,
  });

  final int failGetCount;
  final int initialPage;
  int _getAttempts = 0;
  int? _savedPage;

  @override
  Future<void> clearLastVisitedPage() async {
    _savedPage = null;
  }

  @override
  Future<int?> getLastVisitedPage() async {
    _getAttempts++;
    if (_getAttempts <= failGetCount) {
      throw Exception('boom');
    }
    return _savedPage ?? initialPage;
  }

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {
    _savedPage = pageNumber;
  }
}
