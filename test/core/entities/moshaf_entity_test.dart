import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/entities/moshaf_entity.dart';

void main() {
  group('MoshafEntity', () {
    const Map<String, Object> tMoshafJson = {
      'id': 1,
      'name': "Hafs A'n Assem",
      'server': 'https://server.mp3quran.net/minsh',
      'surahTotal': 114,
      'moshafType': 1,
      'surahList': '1,2,3,4,5,6,7,8,9,10',
    };

    const tMoshaf = MoshafEntity(
      id: 1,
      name: "Hafs A'n Assem",
      server: 'https://server.mp3quran.net/minsh',
      surahTotal: 114,
      moshafType: 1,
      surahList: '1,2,3,4,5,6,7,8,9,10',
    );

    test('should create instance with all required fields', () {
      // arrange & act
      const moshaf = MoshafEntity(
        id: 1,
        name: 'Test Moshaf',
        server: 'https://example.com',
        surahTotal: 114,
        moshafType: 1,
        surahList: '1,2,3',
      );

      // assert
      expect(moshaf.id, 1);
      expect(moshaf.name, 'Test Moshaf');
      expect(moshaf.server, 'https://example.com');
      expect(moshaf.surahTotal, 114);
      expect(moshaf.moshafType, 1);
      expect(moshaf.surahList, '1,2,3');
    });

    test('should deserialize from JSON', () {
      // act
      final moshaf = MoshafEntity.fromJson(tMoshafJson);

      // assert
      expect(moshaf, tMoshaf);
      expect(moshaf.id, 1);
      expect(moshaf.name, "Hafs A'n Assem");
      expect(moshaf.server, 'https://server.mp3quran.net/minsh');
      expect(moshaf.surahTotal, 114);
      expect(moshaf.moshafType, 1);
      expect(moshaf.surahList, '1,2,3,4,5,6,7,8,9,10');
    });

    test('should serialize to JSON', () {
      // act
      final Map<String, dynamic> json = tMoshaf.toJson();

      // assert
      expect(json, tMoshafJson);
      expect(json['id'], 1);
      expect(json['name'], "Hafs A'n Assem");
      expect(json['server'], 'https://server.mp3quran.net/minsh');
      expect(json['surahTotal'], 114);
      expect(json['moshafType'], 1);
      expect(json['surahList'], '1,2,3,4,5,6,7,8,9,10');
    });

    test('should support value equality', () {
      // arrange
      const moshaf1 = MoshafEntity(
        id: 1,
        name: 'Test Moshaf',
        server: 'https://example.com',
        surahTotal: 114,
        moshafType: 1,
        surahList: '1,2,3',
      );

      const moshaf2 = MoshafEntity(
        id: 1,
        name: 'Test Moshaf',
        server: 'https://example.com',
        surahTotal: 114,
        moshafType: 1,
        surahList: '1,2,3',
      );

      // assert
      expect(moshaf1, moshaf2);
    });

    test('should not be equal when properties differ', () {
      // arrange
      const moshaf1 = MoshafEntity(
        id: 1,
        name: 'Test Moshaf',
        server: 'https://example.com',
        surahTotal: 114,
        moshafType: 1,
        surahList: '1,2,3',
      );

      const moshaf2 = MoshafEntity(
        id: 2,
        name: 'Different Moshaf',
        server: 'https://different.com',
        surahTotal: 30,
        moshafType: 2,
        surahList: '4,5,6',
      );

      // assert
      expect(moshaf1, isNot(moshaf2));
    });

    test('props should contain all fields', () {
      // arrange
      const moshaf = MoshafEntity(
        id: 1,
        name: 'Test Moshaf',
        server: 'https://example.com',
        surahTotal: 114,
        moshafType: 1,
        surahList: '1,2,3',
      );

      // assert
      expect(moshaf.props, [
        1,
        'Test Moshaf',
        'https://example.com',
        114,
        1,
        '1,2,3',
      ]);
    });

    test('should handle JSON round-trip correctly', () {
      // arrange
      const original = MoshafEntity(
        id: 99,
        name: 'Round Trip Test',
        server: 'https://test.com',
        surahTotal: 50,
        moshafType: 3,
        surahList: '10,20,30',
      );

      // act
      final Map<String, dynamic> json = original.toJson();
      final deserialized = MoshafEntity.fromJson(json);

      // assert
      expect(deserialized, original);
    });
  });
}
