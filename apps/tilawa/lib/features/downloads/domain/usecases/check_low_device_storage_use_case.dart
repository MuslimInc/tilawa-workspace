import 'package:injectable/injectable.dart';

import '../constants/download_storage_estimates.dart';
import '../services/device_storage_service.dart';

/// Returns true when free storage is likely below [estimatedRequiredBytes].
@injectable
class CheckLowDeviceStorageUseCase {
  const CheckLowDeviceStorageUseCase(this._deviceStorageService);

  final DeviceStorageService _deviceStorageService;

  Future<bool> call({required int estimatedRequiredBytes}) async {
    if (estimatedRequiredBytes <= 0) {
      return false;
    }

    final int? availableBytes = await _deviceStorageService.getAvailableBytes();
    if (availableBytes == null) {
      return false;
    }

    final int requiredBytes =
        estimatedRequiredBytes > DownloadStorageEstimates.minimumFreeBytes
        ? estimatedRequiredBytes
        : DownloadStorageEstimates.minimumFreeBytes;

    return availableBytes < requiredBytes;
  }
}
