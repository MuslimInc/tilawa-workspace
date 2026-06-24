import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:tilawa/features/qibla/domain/usecases/request_location_permission_use_case.dart';

import 'check_location_service_use_case_test.mocks.dart';

// Reuse mock from check_location_service_use_case_test if possible or generate new.
// Since mocks are generated in separate files usually, correct way is to use its own mock or import if aligned.
// I will reuse the mock class if I can import it, but `build_runner` generates specific file.
// I'll annotate here too to generate its own mock file or just put it there.
// I'll GenerateMocks here to be safe.

@GenerateMocks([QiblaRepository])
void main() {
  late RequestLocationPermissionUseCase useCase;
  late MockQiblaRepository mockQiblaRepository;

  setUp(() {
    mockQiblaRepository = MockQiblaRepository();
    useCase = RequestLocationPermissionUseCase(mockQiblaRepository);
  });

  test('should call requestLocationPermission from repository', () async {
    when(
      mockQiblaRepository.requestLocationPermission(),
    ).thenAnswer((_) async => true);

    final Either<Failure, bool> result = await useCase(const NoParams());

    expect(result, const Right<Failure, bool>(true));
    verify(mockQiblaRepository.requestLocationPermission()).called(1);
    verifyNoMoreInteractions(mockQiblaRepository);
  });

  test('returns ServerFailure when repository throws', () async {
    when(
      mockQiblaRepository.requestLocationPermission(),
    ).thenThrow(Exception('permission dialog failed'));

    final Either<Failure, bool> result = await useCase(const NoParams());

    expect(result, isA<Left<Failure, bool>>());
    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
