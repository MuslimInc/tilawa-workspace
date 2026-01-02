import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/services/audio_position_service.dart';

void main() {
  group('AudioPositionServiceImpl', () {
    test('position returns AudioService.position stream', () {
      // Arrange
      final service = AudioPositionServiceImpl();

      // Act
      final Stream<Duration> positionStream = service.position;

      // Assert
      expect(positionStream, isA<Stream<Duration>>());
      expect(positionStream, equals(AudioService.position));
    });
  });
}
