import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/downloads/data/models/download_progress.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';

void main() {
  group('DownloadProgress', () {
    test('props contains all fields', () {
      const progress = DownloadProgress(
        id: '123',
        status: DownloadStatus.downloading,
        progress: 0.5,
        downloadedSize: 100,
        fileSize: 200,
      );

      expect(progress.props, [
        '123',
        DownloadStatus.downloading,
        0.5,
        100,
        200,
      ]);
    });

    test('supports value equality', () {
      const progress1 = DownloadProgress(
        id: '123',
        status: DownloadStatus.downloading,
        progress: 0.5,
        downloadedSize: 100,
        fileSize: 200,
      );

      const progress2 = DownloadProgress(
        id: '123',
        status: DownloadStatus.downloading,
        progress: 0.5,
        downloadedSize: 100,
        fileSize: 200,
      );

      const progress3 = DownloadProgress(
        id: '124',
        status: DownloadStatus.downloading,
        progress: 0.5,
        downloadedSize: 100,
        fileSize: 200,
      );

      expect(progress1, equals(progress2));
      expect(progress1, isNot(equals(progress3)));
    });
  });
}
