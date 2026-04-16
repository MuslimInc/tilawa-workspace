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
      'quran_image_widget_test_',
    );
    headerPath = '${tempDirectory.path}/sura_header_banner.webp';
    await File(headerPath).writeAsBytes([0x52, 0x49, 0x46, 0x46]);

    await sl.unregister<LastVisitedPageRepository>();
    sl.registerLazySingleton<LastVisitedPageRepository>(
      _InMemoryLastVisitedPageRepository.new,
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
    await sl.unregister<PrepareQuranImageCacheUseCase>();
    sl.registerLazySingleton<PrepareQuranImageCacheUseCase>(
      () => PrepareQuranImageCacheUseCase(sl<QuranImageCacheRepository>()),
    );
  });

  tearDown(() async {
    await sl.reset();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('Quran image app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranImageApp());
    await tester.pumpAndSettle();

    // Verify that the app builds without errors
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
  }) {
    return null;
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
  String? surahHeaderBannerFilePath() => _headerPath;
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
  double get preloadProgress => 1.0;

  @override
  List<VerseMarkerData> getMarkersForPage(int pageNumber) => const [];

  @override
  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber) async =>
      const [];

  @override
  Future<void> init({
    bool forceDebugSource = false,
    bool? preloadAllPages,
  }) async {}
}

class _InMemoryLastVisitedPageRepository implements LastVisitedPageRepository {
  int? _lastVisitedPage;

  @override
  Future<void> clearLastVisitedPage() async {
    _lastVisitedPage = null;
  }

  @override
  Future<int?> getLastVisitedPage() async {
    return _lastVisitedPage;
  }

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {
    _lastVisitedPage = pageNumber;
  }
}
