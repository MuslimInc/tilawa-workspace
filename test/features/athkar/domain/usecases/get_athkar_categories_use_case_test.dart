import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/usecases/usecase.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/athkar/domain/entities/athkar_category.dart';
import 'package:muzakri/features/athkar/domain/entities/athkar_item.dart';
import 'package:muzakri/features/athkar/domain/repositories/athkar_repository.dart';
import 'package:muzakri/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';

import 'get_athkar_categories_use_case_test.mocks.dart';

@GenerateMocks([AthkarRepository])
void main() {
  late GetAthkarCategoriesUseCase useCase;
  late MockAthkarRepository mockRepository;

  setUp(() {
    provideDummy<ResultFuture<List<AthkarCategory>>>(
      Future.value(const Right([])),
    );
    provideDummy<ResultFuture<List<AthkarItem>>>(Future.value(const Right([])));
    provideDummy<Either<Failure, List<AthkarCategory>>>(const Right([]));
    provideDummy<Either<Failure, List<AthkarItem>>>(const Right([]));
    mockRepository = MockAthkarRepository();
    useCase = GetAthkarCategoriesUseCase(mockRepository);
  });

  const tCategories = [
    AthkarCategory(
      id: 1,
      nameAr: 'أذكار الصباح',
      nameEn: 'Morning Athkar',
      icon: 'wb_sunny_rounded',
    ),
  ];

  test('should get athkar categories from the repository', () async {
    // Arrange
    when(
      mockRepository.getCategories(),
    ).thenAnswer((_) async => const Right(tCategories));

    // Act
    final Either<Failure, List<AthkarCategory>> result = await useCase(
      const NoParams(),
    );

    // Assert
    expect(result.isRight, true);
    result.fold(
      (_) => fail('Should be Right'),
      (categories) => expect(categories, tCategories),
    );
    verify(mockRepository.getCategories());
    verifyNoMoreInteractions(mockRepository);
  });
}
