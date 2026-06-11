import 'dart:io';

import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/services/device_storage_service.dart';

@LazySingleton(as: DeviceStorageService)
class DeviceStorageServiceImpl implements DeviceStorageService {
  DeviceStorageServiceImpl(this._diskSpacePlus);

  final DiskSpacePlus _diskSpacePlus;

  @override
  Future<int?> getAvailableBytes() async {
    try {
      final String? downloadVolumePath = await _downloadVolumePath();
      if (downloadVolumePath != null) {
        final double? volumeFreeMegabytes = await _diskSpacePlus
            .getFreeDiskSpaceForPath(downloadVolumePath);
        if (volumeFreeMegabytes != null) {
          return _megabytesToBytes(volumeFreeMegabytes);
        }
      }

      final double? deviceFreeMegabytes = await _diskSpacePlus.getFreeDiskSpace;
      if (deviceFreeMegabytes == null) {
        return null;
      }
      return _megabytesToBytes(deviceFreeMegabytes);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _downloadVolumePath() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    }
    directory ??= await getApplicationDocumentsDirectory();
    return directory.path;
  }

  int _megabytesToBytes(double megabytes) => (megabytes * 1024 * 1024).round();
}
