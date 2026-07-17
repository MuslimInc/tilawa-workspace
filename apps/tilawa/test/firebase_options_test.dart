import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_environment.dart';
import 'package:tilawa/firebase_options.dart';

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('selects distinct iOS Firebase apps per environment', () {
    final development = DefaultFirebaseOptions.optionsForEnvironment(
      AppEnvironment.development,
    );
    final staging = DefaultFirebaseOptions.optionsForEnvironment(
      AppEnvironment.staging,
    );
    final production = DefaultFirebaseOptions.optionsForEnvironment(
      AppEnvironment.production,
    );

    check(
      development.appId,
    ).equals('1:181575856185:ios:4c3a8e674c6138d0381de8');
    check(development.iosBundleId).equals('com.tilawa.app.dev');

    check(staging.appId).equals('1:181575856185:ios:122febc64df470f2381de8');
    check(staging.iosBundleId).equals('com.tilawa.app.staging');

    check(production.appId).equals('1:181575856185:ios:c2b2bf0966057dfd381de8');
    check(production.iosBundleId).equals('com.memuslim.app');
  });

  test('selects distinct Android Firebase apps per environment', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final development = DefaultFirebaseOptions.optionsForEnvironment(
      AppEnvironment.development,
    );
    final staging = DefaultFirebaseOptions.optionsForEnvironment(
      AppEnvironment.staging,
    );
    final production = DefaultFirebaseOptions.optionsForEnvironment(
      AppEnvironment.production,
    );

    check(
      development.appId,
    ).equals('1:181575856185:android:43541a93da054b8e381de8');
    check(
      staging.appId,
    ).equals('1:181575856185:android:17fc49ff4a5b1366381de8');
    check(
      production.appId,
    ).equals('1:181575856185:android:d43fb05037208139381de8');
  });
}
