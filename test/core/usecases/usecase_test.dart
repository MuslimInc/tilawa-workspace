import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/core/usecases/usecase.dart';

void main() {
  group('NoParams', () {
    test('should create instance with const constructor', () {
      // act
      const params = NoParams();

      // assert
      expect(params, isNotNull);
      expect(params, isA<NoParams>());
    });

    test('should support value equality', () {
      // arrange
      const params1 = NoParams();
      const params2 = NoParams();

      // assert
      expect(params1, params2);
    });

    test('props should return empty list', () {
      // arrange
      const params = NoParams();

      // assert
      expect(params.props, isEmpty);
      expect(params.props, []);
    });

    test('should have consistent hashCode for same instance', () {
      // arrange
      const params1 = NoParams();
      const params2 = NoParams();

      // assert
      expect(params1.hashCode, params2.hashCode);
    });
  });
}
