import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/athkar/domain/entities/athkar_category.dart';
import 'package:muzakri/features/athkar/domain/entities/athkar_item.dart';
import 'package:muzakri/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';

import 'get_athkar_categories_use_case_test.mocks.dart';

void main() {
  late GetAthkarByCategoryUseCase useCase;
  late MockAthkarRepository mockRepository;

  setUp(() {
    provideDummy<ResultFuture<List<AthkarCategory>>>(
      Future.value(const Right([])),
    );
    provideDummy<ResultFuture<List<AthkarItem>>>(Future.value(const Right([])));
    provideDummy<Either<Failure, List<AthkarCategory>>>(const Right([]));
    provideDummy<Either<Failure, List<AthkarItem>>>(const Right([]));
    mockRepository = MockAthkarRepository();
    useCase = GetAthkarByCategoryUseCase(mockRepository);
  });

  const tCategoryId = 1;
  const tAthkarItems = [
    AthkarItem(
      id: 1,
      categoryId: 1,
      textAr: 'Test Ar',
      textEn: 'Test En',
      count: 1,
      reference: 'Test Ref',
    ),
  ];

  test('should get athkar items for a category from the repository', () async {
    // Arrange
    when(
      mockRepository.getAthkarByCategory(any),
    ).thenAnswer((_) async => const Right(tAthkarItems));

    // Act
    final Either<Failure, List<AthkarItem>> result = await useCase(tCategoryId);

    // Assert
    expect(result.isRight, true);
    result.fold(
      (_) => fail('Should be Right'),
      (items) => expect(items, tAthkarItems),
    );
    verify(mockRepository.getAthkarByCategory(tCategoryId));
    verifyNoMoreInteractions(mockRepository);
  });
}
