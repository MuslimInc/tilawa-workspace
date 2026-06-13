import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/domain/constants/download_storage_estimates.dart';
import 'package:tilawa/features/downloads/domain/services/device_storage_service.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_low_device_storage_use_case.dart';

class _MockDeviceStorageService extends Mock implements DeviceStorageService {}

void main() {
  late CheckLowDeviceStorageUseCase useCase;
  late _MockDeviceStorageService mockDeviceStorageService;

  setUp(() {
    mockDeviceStorageService = _MockDeviceStorageService();
    useCase = CheckLowDeviceStorageUseCase(mockDeviceStorageService);
  });

  test('returns false when estimated size is zero', () async {
    final bool result = await useCase(estimatedRequiredBytes: 0);

    expect(result, isFalse);
    verifyNever(() => mockDeviceStorageService.getAvailableBytes());
  });

  test('returns false when available storage cannot be read', () async {
    when(
      () => mockDeviceStorageService.getAvailableBytes(),
    ).thenAnswer((_) async => null);

    final bool result = await useCase(estimatedRequiredBytes: 1024);

    expect(result, isFalse);
  });

  test('returns true when available storage is below estimate', () async {
    when(
      () => mockDeviceStorageService.getAvailableBytes(),
    ).thenAnswer((_) async => 1000);

    final bool result = await useCase(estimatedRequiredBytes: 2000);

    expect(result, isTrue);
  });

  test('returns false when available storage meets estimate', () async {
    const int estimate = DownloadStorageEstimates.minimumFreeBytes + 1000;
    when(
      () => mockDeviceStorageService.getAvailableBytes(),
    ).thenAnswer((_) async => estimate + 5000);

    final bool result = await useCase(estimatedRequiredBytes: estimate);

    expect(result, isFalse);
  });

  test('returns true when free space is below minimum floor', () async {
    when(
      () => mockDeviceStorageService.getAvailableBytes(),
    ).thenAnswer(
      (_) async => DownloadStorageEstimates.minimumFreeBytes - 1,
    );

    final bool result = await useCase(
      estimatedRequiredBytes: DownloadStorageEstimates.maxSurahBytes,
    );

    expect(result, isTrue);
  });
}
