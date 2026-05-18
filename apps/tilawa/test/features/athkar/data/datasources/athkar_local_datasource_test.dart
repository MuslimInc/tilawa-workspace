import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_local_datasource.dart';
import 'package:tilawa/features/athkar/data/models/athkar_category_model.dart';
import 'package:tilawa/features/athkar/data/models/athkar_item_model.dart';

import 'athkar_local_datasource_test.mocks.dart';

@GenerateMocks([AssetBundle])
void main() {
  late AthkarLocalDataSourceImpl dataSource;
  late MockAssetBundle mockAssetBundle;

  const tAssetPath = 'assets/data/athkar.json';

  final Map<String, List<Map<String, Object>>> tAthkarJson = {
    'categories': [
      {
        'id': 1,
        'name_ar': 'أذكار الصباح',
        'name_en': 'Morning Athkar',
        'icon': 'wb_sunny_rounded',
      },
    ],
    'athkar': [
      {
        'id': 1,
        'category_id': 1,
        'text_ar': 'Test Ar',
        'text_en': 'Test En',
        'count': 1,
        'reference': 'Test Ref',
      },
      {
        'id': 2,
        'category_id': 2,
        'text_ar': 'Test Ar 2',
        'text_en': 'Test En 2',
        'count': 2,
        'reference': 'Test Ref 2',
      },
    ],
  };

  setUp(() {
    mockAssetBundle = MockAssetBundle();
    dataSource = AthkarLocalDataSourceImpl(assetBundle: mockAssetBundle);
  });

  group('getCategories', () {
    test('should return a list of AthkarCategoryModel from JSON', () async {
      // Arrange
      when(
        mockAssetBundle.loadString(tAssetPath),
      ).thenAnswer((_) async => jsonEncode(tAthkarJson));

      // Act
      final List<AthkarCategoryModel> result = await dataSource.getCategories();

      // Assert
      expect(result.length, 1);
      expect(result.first, isA<AthkarCategoryModel>());
      expect(result.first.id, 1);
      expect(result.first.nameAr, 'أذكار الصباح');
      expect(result.first.nameEn, 'Morning Athkar');
      verify(mockAssetBundle.loadString(tAssetPath));
    });
  });

  group('getAthkarByCategory', () {
    test(
      'should return a filtered list of AthkarItemModel from JSON',
      () async {
        // Arrange
        when(
          mockAssetBundle.loadString(tAssetPath),
        ).thenAnswer((_) async => jsonEncode(tAthkarJson));

        // Act
        final List<AthkarItemModel> result = await dataSource
            .getAthkarByCategory(1);

        // Assert
        expect(result.length, 1);
        expect(result.first, isA<AthkarItemModel>());
        expect(result.first.id, 1);
        expect(result.first.categoryId, 1);
        verify(mockAssetBundle.loadString(tAssetPath));
      },
    );

    test('should return an empty list if no items match categoryId', () async {
      // Arrange
      when(
        mockAssetBundle.loadString(tAssetPath),
      ).thenAnswer((_) async => jsonEncode(tAthkarJson));

      // Act
      final List<AthkarItemModel> result = await dataSource.getAthkarByCategory(
        3,
      );

      // Assert
      expect(result, isEmpty);
      verify(mockAssetBundle.loadString(tAssetPath));
    });
  });
}
