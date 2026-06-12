/// Reads available on-device storage for download warnings.
abstract class DeviceStorageService {
  /// Free bytes on the device volume used for downloads, or null if unknown.
  Future<int?> getAvailableBytes();
}
