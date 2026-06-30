import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';

void main() {
  group('AppStartupTasks.useAppCheckDebugProviders', () {
    test('debug mode selects App Check debug providers', () {
      expect(
        AppStartupTasks.useAppCheckDebugProviders(debugMode: true),
        isTrue,
      );
    });

    test('profile mode selects production App Check providers', () {
      // Profile: kProfileMode && !kDebugMode && !kReleaseMode
      expect(
        AppStartupTasks.useAppCheckDebugProviders(debugMode: false),
        isFalse,
      );
    });

    test('release mode selects production App Check providers', () {
      expect(
        AppStartupTasks.useAppCheckDebugProviders(debugMode: false),
        isFalse,
      );
    });

    test(
      'profile is not misclassified by former !kReleaseMode gate',
      () {
        const bool releaseMode = false;
        const bool debugMode = false;

        expect(releaseMode, isFalse);
        expect(debugMode, isFalse);
        expect(!releaseMode, isTrue);
        expect(
          AppStartupTasks.useAppCheckDebugProviders(debugMode: debugMode),
          isFalse,
        );
      },
    );

    test('matches kDebugMode in the test VM', () {
      expect(
        AppStartupTasks.useAppCheckDebugProviders(),
        equals(kDebugMode),
      );
    });
  });
}
