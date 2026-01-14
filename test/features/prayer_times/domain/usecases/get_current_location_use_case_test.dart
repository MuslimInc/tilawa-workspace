import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/core.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_current_location_use_case.dart';

import 'get_current_location_use_case_test.mocks.dart';

@GenerateMocks([PrayerTimesRepository])
void main() {
  late GetCurrentLocationUseCase useCase;
  late MockPrayerTimesRepository mockRepository;

  setUp(() {
    mockRepository = MockPrayerTimesRepository();
    useCase = GetCurrentLocationUseCase(mockRepository);
  });

  final tLocationResult = LocationResult(latitude: 10.0, longitude: 10.0);

  test('should return location when permission granted', () async {
    // Arrange
    when(mockRepository.hasLocationPermission()).thenAnswer((_) async => true);
    when(
      mockRepository.getCurrentLocation(),
    ).thenAnswer((_) async => tLocationResult);

    // Act
    final Either<Failure, LocationResult> result = await useCase();

    // Assert
    expect(result, Right<Failure, LocationResult>(tLocationResult));
    verify(mockRepository.getCurrentLocation());
  });

  test('should request permission if not granted', () async {
    // Arrange
    when(mockRepository.hasLocationPermission()).thenAnswer((_) async => false);
    when(
      mockRepository.requestLocationPermission(),
    ).thenAnswer((_) async => true);
    when(
      mockRepository.getCurrentLocation(),
    ).thenAnswer((_) async => tLocationResult);

    // Act
    final Either<Failure, LocationResult> result = await useCase();

    // Assert
    expect(result, Right<Failure, LocationResult>(tLocationResult));
    verify(mockRepository.requestLocationPermission());
  });

  test('should return failure if permission denied', () async {
    // Arrange
    when(mockRepository.hasLocationPermission()).thenAnswer((_) async => false);
    when(
      mockRepository.requestLocationPermission(),
    ).thenAnswer((_) async => false);

    // Act
    final Either<Failure, LocationResult> result = await useCase();

    // Assert
    expect(result.fold((l) => l, (r) => null), isA<PermissionFailure>());
  });

  test('should return failure if location result has error', () async {
    // Arrange
    when(mockRepository.hasLocationPermission()).thenAnswer((_) async => true);
    when(
      mockRepository.getCurrentLocation(),
    ).thenAnswer((_) async => LocationResult.error('Error'));

    // Act
    final Either<Failure, LocationResult> result = await useCase();

    // Assert
    expect(result.fold((l) => l, (r) => null), isA<UnexpectedFailure>());
  });
}
