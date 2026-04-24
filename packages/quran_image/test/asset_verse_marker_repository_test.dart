import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/entities/verse_marker_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, List<int>> assets;

  setUp(() {
    assets = <String, List<int>>{
      'assets/data/verse_marker_coordinates.json': utf8.encode(
        json.encode(<String, Object>{
          '1': <Map<String, Object>>[
            <String, Object>{'sura': 1, 'ayah': 1, 'line': 0, 'centerX': 0.25},
            <String, Object>{'sura': 1, 'ayah': 2, 'line': 1, 'centerX': 0.75},
          ],
          '2': <Map<String, Object>>[
            <String, Object>{'sura': 2, 'ayah': 255, 'line': 5, 'centerX': 0.5},
          ],
        }),
      ),
      'assets/data/quran_marker_debug_coordinates/1.json': utf8.encode(
        json.encode(<Map<String, Object>>[
          <String, Object>{'sura': 18, 'ayah': 7, 'line': 2, 'centerX': 0.4},
        ]),
      ),
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          if (message == null) {
            return null;
          }
          final key = utf8.decode(message.buffer.asUint8List());
          final bytes = assets[key];
          if (bytes == null) {
            return null;
          }
          return ByteData.sublistView(Uint8List.fromList(bytes));
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test(
    'production init lazy-decodes pages and caches immutable markers',
    () async {
      final repository = AssetVerseMarkerRepository();

      await repository.init();

      expect(repository.isInitialized, isTrue);
      expect(repository.initializedNotifier.value, isTrue);
      expect(repository.isDebugMode, isFalse);
      expect(repository.isPreloading, isFalse);
      expect(repository.preloadProgress, 1.0);

      final pageOneMarkers = repository.getMarkersForPage(1);
      expect(pageOneMarkers, hasLength(2));
      expect(pageOneMarkers.first.sura, 1);
      expect(pageOneMarkers.first.ayah, 1);
      expect(pageOneMarkers.last.centerX, 0.75);
      expect(
        () => pageOneMarkers.add(
          const VerseMarkerData(sura: 1, ayah: 3, line: 2, centerX: 0.5),
        ),
        throwsUnsupportedError,
      );

      final cachedAgain = repository.getMarkersForPage(1);
      expect(identical(pageOneMarkers, cachedAgain), isTrue);

      final pageTwoMarkers = repository.getMarkersForPage(2);
      expect(pageTwoMarkers.single.ayah, 255);
      expect(repository.getMarkersForPage(604), isEmpty);

      repository.dispose();
    },
  );

  test('debug init and setDataSource load page data asynchronously', () async {
    final repository = AssetVerseMarkerRepository();

    await repository.init(forceDebugSource: true, preloadAllPages: false);

    expect(repository.isInitialized, isTrue);
    expect(repository.isDebugMode, isTrue);
    expect(repository.getMarkersForPage(1), isEmpty);

    final debugMarkers = await repository.getMarkersForPageAsync(1);
    expect(debugMarkers, hasLength(1));
    expect(debugMarkers.single.sura, 18);
    expect(debugMarkers.single.ayah, 7);
    expect(
      () => debugMarkers.add(
        const VerseMarkerData(sura: 18, ayah: 8, line: 3, centerX: 0.5),
      ),
      throwsUnsupportedError,
    );

    await repository.setDataSource(MarkerDataSource.production);
    expect(repository.isDebugMode, isFalse);
    expect(repository.isInitialized, isTrue);
    expect(repository.preloadProgress, 1.0);
    expect(repository.getMarkersForPage(2).single.ayah, 255);

    repository.dispose();
  });
}
