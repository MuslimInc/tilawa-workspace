import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image_flutter/data/services/flutter_decoded_quran_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late String imagePath;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'decoded_quran_image_cache_test_',
    );
    imagePath = '${tempDirectory.path}/pixel.png';
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..color = const ui.Color(0xFF00FF00),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    await File(imagePath).writeAsBytes(bytes!.buffer.asUint8List());
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'prewarms line and file images, trims cache, and survives resets',
    () async {
      final cache = FlutterDecodedQuranImageCache();

      await cache.prewarmLineImage(imagePath: imagePath, cacheWidth: 120);
      await cache.prewarmLineImage(imagePath: imagePath, cacheWidth: 120);
      await cache.prewarmFileImage(imagePath);

      for (var width = 1; width <= 110; width++) {
        await cache.prewarmLineImage(imagePath: imagePath, cacheWidth: width);
      }

      cache.handleMemoryPressure();

      await cache.prewarmLineImage(imagePath: imagePath, cacheWidth: 120);
      await cache.prewarmFileImage(imagePath);
    },
  );

  test('propagates image resolution failures', () async {
    final cache = FlutterDecodedQuranImageCache();

    await expectLater(
      cache.prewarmLineImage(
        imagePath: '${tempDirectory.path}/missing.png',
        cacheWidth: 100,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
