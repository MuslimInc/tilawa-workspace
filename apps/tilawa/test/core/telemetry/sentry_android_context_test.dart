import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/telemetry/sentry_android_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SentryAndroidContext', () {
    test('ensurePluginContext is no-op off Android', () async {
      await expectLater(SentryAndroidContext.ensurePluginContext(), completes);
    });

    test('isNativeSdkInitialized is false without platform channel', () async {
      expect(await SentryAndroidContext.isNativeSdkInitialized(), isFalse);
    });
  });
}
