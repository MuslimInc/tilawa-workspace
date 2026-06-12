import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_error_guard.dart';

void main() {
  late FlutterExceptionHandler? savedOnError;
  late void Function(FlutterErrorDetails) savedPresentError;
  late ui.ErrorCallback? savedPlatformOnError;

  setUp(() {
    savedOnError = FlutterError.onError;
    savedPresentError = FlutterError.presentError;
    savedPlatformOnError = ui.PlatformDispatcher.instance.onError;
    // Keep test output clean — the guard presents every captured error.
    FlutterError.presentError = (FlutterErrorDetails details) {};
    AppErrorGuard.resetForTesting();
  });

  tearDown(() {
    AppErrorGuard.resetForTesting();
    FlutterError.onError = savedOnError;
    FlutterError.presentError = savedPresentError;
    ui.PlatformDispatcher.instance.onError = savedPlatformOnError;
  });

  FlutterErrorDetails detailsFor(String message) {
    return FlutterErrorDetails(exception: StateError(message));
  }

  test('install takes over both global error hooks', () {
    AppErrorGuard.install();

    expect(FlutterError.onError, isNot(equals(savedOnError)));
    expect(
      ui.PlatformDispatcher.instance.onError,
      isNot(equals(savedPlatformOnError)),
    );
  });

  test('buffers Flutter errors before attach and replays them in order', () {
    AppErrorGuard.install();
    FlutterError.onError!(detailsFor('first'));
    FlutterError.onError!(detailsFor('second'));

    final List<String> reported = <String>[];
    AppErrorGuard.attachReporter(
      onFlutterError: (FlutterErrorDetails details) {
        reported.add(details.exception.toString());
      },
      onPlatformError: (Object error, StackTrace stack) => true,
    );

    expect(reported, <String>['Bad state: first', 'Bad state: second']);
  });

  test('forwards Flutter errors directly once a reporter is attached', () {
    AppErrorGuard.install();
    final List<String> reported = <String>[];
    AppErrorGuard.attachReporter(
      onFlutterError: (FlutterErrorDetails details) {
        reported.add(details.exception.toString());
      },
      onPlatformError: (Object error, StackTrace stack) => true,
    );

    FlutterError.onError!(detailsFor('live'));

    expect(reported, <String>['Bad state: live']);
  });

  test('buffers platform errors before attach and replays them', () {
    AppErrorGuard.install();
    final bool handled = ui.PlatformDispatcher.instance.onError!(
      StateError('async boom'),
      StackTrace.current,
    );
    expect(handled, isTrue);

    final List<String> reported = <String>[];
    AppErrorGuard.attachReporter(
      onFlutterError: (FlutterErrorDetails details) {},
      onPlatformError: (Object error, StackTrace stack) {
        reported.add(error.toString());
        return true;
      },
    );

    expect(reported, <String>['Bad state: async boom']);
  });

  test('keeps only the earliest maxBufferedErrors errors', () {
    AppErrorGuard.install();
    for (int i = 0; i < AppErrorGuard.maxBufferedErrors + 5; i++) {
      FlutterError.onError!(detailsFor('error $i'));
    }

    final List<String> reported = <String>[];
    AppErrorGuard.attachReporter(
      onFlutterError: (FlutterErrorDetails details) {
        reported.add(details.exception.toString());
      },
      onPlatformError: (Object error, StackTrace stack) => true,
    );

    expect(reported, hasLength(AppErrorGuard.maxBufferedErrors));
    expect(reported.first, 'Bad state: error 0');
    expect(
      reported.last,
      'Bad state: error ${AppErrorGuard.maxBufferedErrors - 1}',
    );
  });

  test('attachReporter installs the guard when install was never called', () {
    final List<String> reported = <String>[];
    AppErrorGuard.attachReporter(
      onFlutterError: (FlutterErrorDetails details) {
        reported.add(details.exception.toString());
      },
      onPlatformError: (Object error, StackTrace stack) => true,
    );

    FlutterError.onError!(detailsFor('after attach-only'));

    expect(reported, <String>['Bad state: after attach-only']);
  });
}
