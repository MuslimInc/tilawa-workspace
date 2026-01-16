import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/models/position_data.dart';

void main() {
  group('PositionData', () {
    test('should create instance with required fields', () {
      const positionData = PositionData(
        position: Duration(seconds: 10),
        bufferedPosition: Duration(seconds: 15),
        duration: Duration(seconds: 30),
      );

      expect(positionData.position, const Duration(seconds: 10));
      expect(positionData.bufferedPosition, const Duration(seconds: 15));
      expect(positionData.duration, const Duration(seconds: 30));
    });

    test('should serialize to JSON correctly', () {
      const positionData = PositionData(
        position: Duration(seconds: 10),
        bufferedPosition: Duration(seconds: 15),
        duration: Duration(seconds: 30),
      );

      final Map<String, dynamic> json = positionData.toJson();

      expect(json['position'], 10000000);
      expect(json['bufferedPosition'], 15000000);
      expect(json['duration'], 30000000);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'position': 10000000,
        'bufferedPosition': 15000000,
        'duration': 30000000,
      };

      final positionData = PositionData.fromJson(json);

      expect(positionData.position, const Duration(seconds: 10));
      expect(positionData.bufferedPosition, const Duration(seconds: 15));
      expect(positionData.duration, const Duration(seconds: 30));
    });

    test('should round-trip through JSON serialization', () {
      const original = PositionData(
        position: Duration(milliseconds: 1500),
        bufferedPosition: Duration(milliseconds: 2000),
        duration: Duration(milliseconds: 5000),
      );

      final Map<String, dynamic> json = original.toJson();
      final deserialized = PositionData.fromJson(json);

      expect(deserialized.position, original.position);
      expect(deserialized.bufferedPosition, original.bufferedPosition);
      expect(deserialized.duration, original.duration);
    });
  });
}
