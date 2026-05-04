import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/services/app_orientation_service.dart';

void main() {
  group('AppOrientationService', () {
    test('defaultOrientations should contain all 4 orientations', () {
      final orientations = AppOrientationService.defaultOrientations;

      expect(orientations.length, 4);
      expect(orientations, contains(DeviceOrientation.portraitUp));
      expect(orientations, contains(DeviceOrientation.portraitDown));
      expect(orientations, contains(DeviceOrientation.landscapeLeft));
      expect(orientations, contains(DeviceOrientation.landscapeRight));
    });

    test('readerOrientations should contain all 4 orientations', () {
      final orientations = AppOrientationService.readerOrientations;

      expect(orientations.length, 4);
      expect(orientations, contains(DeviceOrientation.portraitUp));
      expect(orientations, contains(DeviceOrientation.portraitDown));
      expect(orientations, contains(DeviceOrientation.landscapeLeft));
      expect(orientations, contains(DeviceOrientation.landscapeRight));
    });
  });
}
