import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration that registers a fake image decoder so that
/// [AssetImage] lookups for package assets (e.g. `mainframe.png`) do not
/// throw during widget tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Provide a 1×1 transparent PNG for any asset image that can't be loaded.
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    ByteData? message,
  ) async {
    // Try the real asset first; if it fails, return a 1×1 transparent PNG.
    try {
      final ByteData? response = await binding.defaultBinaryMessenger.send(
        'flutter/assets',
        message,
      );
      if (response != null && response.lengthInBytes > 0) {
        return response;
      }
    } catch (_) {
      // Fall through to fake image.
    }
    return ByteData.sublistView(_k1x1TransparentPng);
  });

  await testMain();
}

/// Minimal valid 1×1 transparent PNG.
final Uint8List _k1x1TransparentPng = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // RGBA, 8-bit
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
  0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
  0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00, // compressed data
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, // IEND chunk
  0x60, 0x82,
]);
