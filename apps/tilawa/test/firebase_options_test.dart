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
    ).equals('1:181575856185:ios:b2c664fdf9f8ece6381de8');
    check(development.iosBundleId).equals('com.tilawa.app.dev');

    check(staging.appId).equals('1:181575856185:ios:c04495544365732a381de8');
    check(staging.iosBundleId).equals('com.tilawa.app.staging');

    check(production.appId).equals('1:181575856185:ios:c2b2bf0966057dfd381de8');
    check(production.iosBundleId).equals('com.memuslim.app');
  });
}

