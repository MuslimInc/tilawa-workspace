import 'package:checks/checks.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_image/domain/services/decoded_quran_image_cache.dart';
import 'package:tilawa/core/services/app_memory_pressure_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    AppMemoryPressureHandler.resetForTest();
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<DecodedQuranImageCache>()) {
      await getIt.unregister<DecodedQuranImageCache>();
    }
    // Restore Flutter image-cache ceilings mutated by severe release.
    final ImageCache imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSizeBytes = 100 << 20;
    imageCache.maximumSize = 1000;
  });

  test('attach is idempotent and listens for severe channel calls', () async {
    AppMemoryPressureHandler.debugIsAndroidOverride = true;
    const MethodChannel channel = MethodChannel(
      AppMemoryPressureHandler.channelName,
    );
    AppMemoryPressureHandler.attach(channel: channel);
    AppMemoryPressureHandler.attach(channel: channel);

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            const MethodCall('severe', <String, Object?>{'level': 80}),
          ),
          (_) {},
        );

    check(AppMemoryPressureHandler.releaseCallCount).equals(1);
    check(PaintingBinding.instance.imageCache.maximumSizeBytes).equals(
      AppMemoryPressureHandler.severeMaximumSizeBytes,
    );
    check(PaintingBinding.instance.imageCache.maximumSize).equals(
      AppMemoryPressureHandler.severeMaximumSize,
    );
  });

  test('releaseSevereCaches clears registered decoded Quran cache', () {
    final _FakeDecodedCache fake = _FakeDecodedCache();
    GetIt.instance.registerSingleton<DecodedQuranImageCache>(fake);

    AppMemoryPressureHandler.releaseSevereCaches(level: 15);

    check(fake.handleMemoryPressureCalls).equals(1);
    check(AppMemoryPressureHandler.releaseCallCount).equals(1);
  });
}

class _FakeDecodedCache implements DecodedQuranImageCache {
  int handleMemoryPressureCalls = 0;

  @override
  ImageProvider<Object> fileImageProvider({required String imagePath}) {
    throw UnimplementedError();
  }

  @override
  void handleMemoryPressure() {
    handleMemoryPressureCalls++;
  }

  @override
  ImageProvider<Object> lineImageProvider({
    required String imagePath,
    required int cacheWidth,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> prewarmFileImage(String imagePath) {
    throw UnimplementedError();
  }

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) {
    throw UnimplementedError();
  }
}
