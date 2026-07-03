import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

bool _sentryInitializedForTests = false;
bool _platformChannelsMocked = false;

/// Mocks platform channels used by Sentry and crash-reporting tag collection.
void mockSentryPlatformChannels() {
  if (_platformChannelsMocked) {
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel packageInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        packageInfoChannel,
        (MethodCall call) async {
          return <String, String>{
            'appName': 'Tilawa',
            'packageName': 'com.tilawa.app',
            'version': '2.0.18',
            'buildNumber': '72',
            'buildSignature': '',
          };
        },
      );

  const MethodChannel sentryChannel = MethodChannel('sentry_flutter');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        sentryChannel,
        (MethodCall call) async => null,
      );

  const MethodChannel deviceInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/device_info',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        deviceInfoChannel,
        (MethodCall call) async {
          if (call.method == 'getDeviceInfo') {
            return <String, dynamic>{
              'model': 'Mac14,2',
              'computerName': 'Test Mac',
            };
          }
          return null;
        },
      );

  _platformChannelsMocked = true;
}

/// Initializes Sentry once for widget/unit tests that need [Sentry.isEnabled].
Future<void> ensureSentryInitializedForTests() async {
  mockSentryPlatformChannels();
  if (_sentryInitializedForTests) {
    return;
  }

  await SentryFlutter.init(
    (SentryFlutterOptions options) {
      options.dsn = 'https://public@sentry.example/1';
      // ignore: invalid_use_of_internal_member
      options.automatedTestMode = true;
      options.autoInitializeNativeSdk = false;
    },
  );
  _sentryInitializedForTests = true;
}

Widget wrapWithTilawaFeedback(Widget child) {
  return TilawaFeedbackHost(child: child);
}
