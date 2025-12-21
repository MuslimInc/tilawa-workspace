import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/athkar/data/datasources/athkar_local_datasource.dart';
import 'package:muzakri/features/athkar/data/models/athkar_category_model.dart';
import 'package:muzakri/features/athkar/data/models/athkar_item_model.dart';
import 'package:muzakri/features/athkar/data/repositories/athkar_repository_impl.dart';
import 'package:muzakri/features/athkar/domain/entities/athkar_category.dart';
import 'package:muzakri/features/athkar/domain/entities/athkar_item.dart';

import 'athkar_repository_impl_test.mocks.dart';

@GenerateMocks([AthkarLocalDataSource])
void main() {
  late AthkarRepositoryImpl repository;
  late MockAthkarLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockAthkarLocalDataSource();
    repository = AthkarRepositoryImpl(mockLocalDataSource);
  });

  const tCategoryModel = AthkarCategoryModel(
    id: 1,
    nameAr: 'أذكار الصباح',
    nameEn: 'Morning Athkar',
    icon: 'wb_sunny_rounded',
  );

  const tItemModel = AthkarItemModel(
    id: 1,
    categoryId: 1,
    textAr: 'Test Ar',
    textEn: 'Test En',
    count: 1,
    reference: 'Test Ref',
  );

  group('getCategories', () {
    test(
      'should return a list of categories when data source call is successful',
      () async {
        // Arrange
        when(
          mockLocalDataSource.getCategories(),
        ).thenAnswer((_) async => [tCategoryModel]);

        // Act
        final Either<Failure, List<AthkarCategory>> result = await repository
            .getCategories();

        // Assert
        expect(result.isRight, true);
        result.fold(
          (_) => fail('Should be Right'),
          (categories) => expect(categories, [tCategoryModel]),
        );
        verify(mockLocalDataSource.getCategories());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return a ServerFailure when data source call throws an exception',
      () async {
        // Arrange
        when(mockLocalDataSource.getCategories()).thenThrow(Exception('Error'));

        // Act
        final Either<Failure, List<AthkarCategory>> result = await repository
            .getCategories();

        // Assert
        expect(result.isLeft, true);
        result.fold(
          (failure) => expect(failure, const ServerFailure('Exception: Error')),
          (_) => fail('Should be Left'),
        );
        verify(mockLocalDataSource.getCategories());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );
  });

  group('getAthkarByCategory', () {
    test(
      'should return a list of items when data source call is successful',
      () async {
        // Arrange
        when(
          mockLocalDataSource.getAthkarByCategory(any),
        ).thenAnswer((_) async => [tItemModel]);

        // Act
        final Either<Failure, List<AthkarItem>> result = await repository
            .getAthkarByCategory(1);

        // Assert
        expect(result.isRight, true);
        result.fold(
          (_) => fail('Should be Right'),
          (items) => expect(items, [tItemModel]),
        );
        verify(mockLocalDataSource.getAthkarByCategory(1));
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return a ServerFailure when data source call throws an exception',
      () async {
        // Arrange
        when(
          mockLocalDataSource.getAthkarByCategory(any),
        ).thenThrow(Exception('Error'));

        // Act
        final Either<Failure, List<AthkarItem>> result = await repository
            .getAthkarByCategory(1);

        // Assert
        expect(result.isLeft, true);
        result.fold(
          (failure) => expect(failure, const ServerFailure('Exception: Error')),
          (_) => fail('Should be Left'),
        );
        verify(mockLocalDataSource.getAthkarByCategory(1));
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );
  });
}
