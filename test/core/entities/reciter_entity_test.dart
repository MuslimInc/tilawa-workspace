import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/core/entities/moshaf_entity.dart';
import 'package:muzakri/core/entities/reciter_entity.dart';

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

    test('props should contain all fields', () {
      // arrange
      const reciter = ReciterEntity(
        id: 1,
        name: 'Test Reciter',
        letter: 'T',
        date: '2024-01-01',
        moshaf: [tMoshaf],
      );

      // assert
      expect(reciter.props, [
        1,
        'Test Reciter',
        'T',
        '2024-01-01',
        const [tMoshaf],
      ]);
    });
  });
}
