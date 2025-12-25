import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/errors/failures.dart';

void main() {
  group('Failure', () {
    test('should create ServerFailure without message', () {
      // act
      const failure = ServerFailure();

      // assert
      expect(failure, isA<Failure>());
      expect(failure.message, null);
    });

    test('should create ServerFailure with message', () {
      // act
      const failure = ServerFailure('Server error occurred');

      // assert
      expect(failure.message, 'Server error occurred');
    });

    test('should support equality for ServerFailure', () {
      // arrange
      const failure1 = ServerFailure('Error');
      const failure2 = ServerFailure('Error');
      const failure3 = ServerFailure('Different');

      // assert
      expect(failure1, failure2);
      expect(failure1, isNot(failure3));
    });

    test('should create CacheFailure without message', () {
      // act
      const failure = CacheFailure();

      // assert
      expect(failure, isA<Failure>());
      expect(failure.message, null);
    });

    test('should create CacheFailure with message', () {
      // act
      const failure = CacheFailure('Cache error occurred');

      // assert
      expect(failure.message, 'Cache error occurred');
    });

    test('should support equality for CacheFailure', () {
      // arrange
      const failure1 = CacheFailure('Error');
      const failure2 = CacheFailure('Error');
      const failure3 = CacheFailure();

      // assert
      expect(failure1, failure2);
      expect(failure1, isNot(failure3));
    });

    test('should create NetworkFailure without message', () {
      // act
      const failure = NetworkFailure();

      // assert
      expect(failure, isA<Failure>());
      expect(failure.message, null);
    });

    test('should create NetworkFailure with message', () {
      // act
      const failure = NetworkFailure('Network error occurred');

      // assert
      expect(failure.message, 'Network error occurred');
    });

    test('should support equality for NetworkFailure', () {
      // arrange
      const failure1 = NetworkFailure('Error');
      const failure2 = NetworkFailure('Error');
      const failure3 = NetworkFailure('Other error');

      // assert
      expect(failure1, failure2);
      expect(failure1, isNot(failure3));
    });

    test('should create AudioFailure without message', () {
      // act
      const failure = AudioFailure();

      // assert
      expect(failure, isA<Failure>());
      expect(failure.message, null);
    });

    test('should create AudioFailure with message', () {
      // act
      const failure = AudioFailure('Audio error occurred');

      // assert
      expect(failure.message, 'Audio error occurred');
    });

    test('should support equality for AudioFailure', () {
      // arrange
      const failure1 = AudioFailure('Error');
      const failure2 = AudioFailure('Error');
      const failure3 = AudioFailure();

      // assert
      expect(failure1, failure2);
      expect(failure1, isNot(failure3));
    });

    test('props should include message', () {
      // arrange
      const failure = ServerFailure('Test message');

      // assert
      expect(failure.props, ['Test message']);
    });

    test('props should handle null message', () {
      // arrange
      const failure = CacheFailure();

      // assert
      expect(failure.props, [null]);
    });

    test('different failure types with same message should not be equal', () {
      // arrange
      const serverFailure = ServerFailure('Error');
      const cacheFailure = CacheFailure('Error');

      // assert
      expect(serverFailure, isNot(cacheFailure));
    });
  });
}
