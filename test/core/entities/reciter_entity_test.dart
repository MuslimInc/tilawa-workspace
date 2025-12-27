import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/entities/moshaf_entity.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';

void main() {
  group('ReciterEntity', () {
    const tMoshaf = MoshafEntity(
      id: 1,
      name: 'Test Moshaf',
      server: 'https://example.com',
      surahTotal: 114,
      moshafType: 1,
      surahList: '1,2,3',
    );

    test('should create instance with all required fields', () {
      // arrange & act
      const reciter = ReciterEntity(
        id: 1,
        name: 'Test Reciter',
        letter: 'T',
        date: '2024-01-01',
        moshaf: [tMoshaf],
      );

      // assert
      expect(reciter.id, 1);
      expect(reciter.name, 'Test Reciter');
      expect(reciter.letter, 'T');
      expect(reciter.date, '2024-01-01');
      expect(reciter.moshaf, [tMoshaf]);
    });

    test('should support value equality', () {
      // arrange
      const reciter1 = ReciterEntity(
        id: 1,
        name: 'Test Reciter',
        letter: 'T',
        date: '2024-01-01',
        moshaf: [tMoshaf],
      );

      const reciter2 = ReciterEntity(
        id: 1,
        name: 'Test Reciter',
        letter: 'T',
        date: '2024-01-01',
        moshaf: [tMoshaf],
      );

      // assert
      expect(reciter1, reciter2);
    });

    test('should not be equal when properties differ', () {
      // arrange
      const reciter1 = ReciterEntity(
        id: 1,
        name: 'Test Reciter',
        letter: 'T',
        date: '2024-01-01',
        moshaf: [tMoshaf],
      );

      const reciter2 = ReciterEntity(
        id: 2,
        name: 'Different Reciter',
        letter: 'D',
        date: '2024-01-02',
        moshaf: [],
      );

      // assert
      expect(reciter1, isNot(reciter2));
    });

    group('serialization', () {
      test('should work correctly', () {
        // arrange
        const reciter = ReciterEntity(
          id: 1,
          name: 'Test Reciter',
          letter: 'T',
          date: '2024-01-01',
          moshaf: [tMoshaf],
        );

        // act
        final Map<String, dynamic> json = reciter.toJson();
        final result = ReciterEntity.fromJson(json);

        // assert
        expect(result, reciter);
      });
    });
  });
}
