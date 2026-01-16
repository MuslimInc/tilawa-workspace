import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:tilawa/features/qibla/domain/usecases/check_location_service_use_case.dart';

import 'check_location_service_use_case_test.mocks.dart';

@GenerateMocks([QiblaRepository])
void main() {
  late CheckLocationServiceUseCase useCase;
  late MockQiblaRepository mockQiblaRepository;

  setUp(() {
    mockQiblaRepository = MockQiblaRepository();
    useCase = CheckLocationServiceUseCase(mockQiblaRepository);
  });

  test('should call isLocationServiceEnabled from repository', () async {
    when(
      mockQiblaRepository.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);

    final Either<Failure, bool> result = await useCase(const NoParams());

    expect(result, const Right<Failure, bool>(true));
    verify(mockQiblaRepository.isLocationServiceEnabled()).called(1);
    verifyNoMoreInteractions(mockQiblaRepository);
  });
}
