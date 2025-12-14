import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/features/downloads/data/services/helpers/download_status_mapper.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';

void main() {
  late DownloadStatusMapper statusMapper;

  setUp(() {
    statusMapper = DownloadStatusMapper();
  });

  group('DownloadStatusMapper', () {
    test('mapTaskStatusToDownloadStatus maps correctly', () {
      expect(
        statusMapper.mapTaskStatusToDownloadStatus(DownloadTaskStatus.enqueued),
        DownloadStatus.pending,
      );
      expect(
        statusMapper.mapTaskStatusToDownloadStatus(DownloadTaskStatus.running),
        DownloadStatus.downloading,
      );
      expect(
        statusMapper.mapTaskStatusToDownloadStatus(DownloadTaskStatus.complete),
        DownloadStatus.completed,
      );
      expect(
        statusMapper.mapTaskStatusToDownloadStatus(DownloadTaskStatus.failed),
        DownloadStatus.failed,
      );
      expect(
        statusMapper.mapTaskStatusToDownloadStatus(DownloadTaskStatus.canceled),
        DownloadStatus.cancelled,
      );
      expect(
        statusMapper.mapTaskStatusToDownloadStatus(DownloadTaskStatus.paused),
        DownloadStatus.paused,
      );
      // Default case (undefined)
      expect(
        statusMapper.mapTaskStatusToDownloadStatus(
          DownloadTaskStatus.undefined,
        ),
        DownloadStatus.failed,
      );
    });
  });
}
