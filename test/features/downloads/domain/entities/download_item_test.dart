import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';

void main() {
  group('DownloadItem', () {
    final testDateTime = DateTime(2024, 1, 15, 10, 30);
    final completedDateTime = DateTime(2024, 1, 15, 11);

    DownloadItem createTestItem({
      String id = 'test_id',
      String title = 'Test Surah',
      String url = 'https://example.com/audio.mp3',
      String filePath = '/path/to/audio.mp3',
      String reciterName = 'Test Reciter',
      DownloadStatus status = DownloadStatus.completed,
      double progress = 1.0,
      int fileSize = 1024,
      int downloadedSize = 1024,
      DateTime? createdAt,
      DateTime? completedAt,
    }) {
      return DownloadItem(
        id: id,
        title: title,
        url: url,
        filePath: filePath,
        reciterName: reciterName,
        status: status,
        progress: progress,
        fileSize: fileSize,
        downloadedSize: downloadedSize,
        createdAt: createdAt ?? testDateTime,
        completedAt: completedAt,
      );
    }

    group('fromJson', () {
      test('should create correct DownloadItem from valid JSON', () {
        // Arrange
        final Map<String, Object> json = {
          'id': 'json_id',
          'title': 'JSON Surah',
          'url': 'https://example.com/json.mp3',
          'filePath': '/path/to/json.mp3',
          'reciterName': 'JSON Reciter',
          'status': 'completed',
          'progress': 1.0,
          'fileSize': 2048,
          'downloadedSize': 2048,
          'createdAt': '2024-01-15T10:30:00.000',
          'completedAt': '2024-01-15T11:00:00.000',
        };

        // Act
        final item = DownloadItem.fromJson(json);

        // Assert
        expect(item.id, 'json_id');
        expect(item.title, 'JSON Surah');
        expect(item.url, 'https://example.com/json.mp3');
        expect(item.filePath, '/path/to/json.mp3');
        expect(item.reciterName, 'JSON Reciter');
        expect(item.status, DownloadStatus.completed);
        expect(item.progress, 1.0);
        expect(item.fileSize, 2048);
        expect(item.downloadedSize, 2048);
        expect(item.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(item.completedAt, DateTime.parse('2024-01-15T11:00:00.000'));
      });

      test('should handle unknown status with fallback to pending', () {
        // Arrange
        final Map<String, Object?> json = {
          'id': 'test_id',
          'title': 'Test',
          'url': 'https://example.com/test.mp3',
          'filePath': '/path/test.mp3',
          'reciterName': 'Reciter',
          'status': 'unknown_status',
          'progress': 0.0,
          'fileSize': 0,
          'downloadedSize': 0,
          'createdAt': '2024-01-15T10:30:00.000',
          'completedAt': null,
        };

        // Act
        final item = DownloadItem.fromJson(json);

        // Assert
        expect(item.status, DownloadStatus.pending);
      });

      test('should handle null completedAt', () {
        // Arrange
        final Map<String, Object?> json = {
          'id': 'test_id',
          'title': 'Test',
          'url': 'https://example.com/test.mp3',
          'filePath': '/path/test.mp3',
          'reciterName': 'Reciter',
          'status': 'downloading',
          'progress': 0.5,
          'fileSize': 1024,
          'downloadedSize': 512,
          'createdAt': '2024-01-15T10:30:00.000',
          'completedAt': null,
        };

        // Act
        final item = DownloadItem.fromJson(json);

        // Assert
        expect(item.completedAt, isNull);
      });

      test('should parse all status types correctly', () {
        final Map<String, DownloadStatus> statusTests = {
          'pending': DownloadStatus.pending,
          'downloading': DownloadStatus.downloading,
          'completed': DownloadStatus.completed,
          'failed': DownloadStatus.failed,
          'paused': DownloadStatus.paused,
          'cancelled': DownloadStatus.cancelled,
        };

        for (final MapEntry<String, DownloadStatus> entry
            in statusTests.entries) {
          final Map<String, Object> json = {
            'id': 'test_id',
            'title': 'Test',
            'url': 'url',
            'filePath': 'path',
            'reciterName': 'Reciter',
            'status': entry.key,
            'progress': 0.0,
            'fileSize': 0,
            'downloadedSize': 0,
            'createdAt': '2024-01-15T10:30:00.000',
          };

          final item = DownloadItem.fromJson(json);
          expect(
            item.status,
            entry.value,
            reason: 'Status ${entry.key} should parse correctly',
          );
        }
      });
    });

    group('toJson', () {
      test('should produce correct JSON output', () {
        // Arrange
        final DownloadItem item = createTestItem(
          completedAt: completedDateTime,
        );

        // Act
        final Map<String, dynamic> json = item.toJson();

        // Assert
        expect(json['id'], 'test_id');
        expect(json['title'], 'Test Surah');
        expect(json['url'], 'https://example.com/audio.mp3');
        expect(json['filePath'], '/path/to/audio.mp3');
        expect(json['reciterName'], 'Test Reciter');
        expect(json['status'], 'completed');
        expect(json['progress'], 1.0);
        expect(json['fileSize'], 1024);
        expect(json['downloadedSize'], 1024);
        expect(json['createdAt'], testDateTime.toIso8601String());
        expect(json['completedAt'], completedDateTime.toIso8601String());
      });

      test('should include null completedAt when not set', () {
        // Arrange
        final DownloadItem item = createTestItem();

        // Act
        final Map<String, dynamic> json = item.toJson();

        // Assert
        expect(json['completedAt'], isNull);
      });

      test('should produce JSON that can be parsed back', () {
        // Arrange
        final DownloadItem original = createTestItem(
          completedAt: completedDateTime,
        );

        // Act
        final Map<String, dynamic> json = original.toJson();
        final parsed = DownloadItem.fromJson(json);

        // Assert
        expect(parsed, equals(original));
      });
    });

    group('copyWith', () {
      test('should create new instance with modified fields', () {
        // Arrange
        final DownloadItem original = createTestItem();

        // Act
        final DownloadItem modified = original.copyWith(
          title: 'Modified Title',
          status: DownloadStatus.downloading,
          progress: 0.5,
        );

        // Assert
        expect(modified.title, 'Modified Title');
        expect(modified.status, DownloadStatus.downloading);
        expect(modified.progress, 0.5);
        // Original should be unchanged
        expect(original.title, 'Test Surah');
        expect(original.status, DownloadStatus.completed);
        expect(original.progress, 1.0);
      });

      test('should preserve unchanged fields', () {
        // Arrange
        final DownloadItem original = createTestItem();

        // Act
        final DownloadItem modified = original.copyWith(title: 'New Title');

        // Assert
        expect(modified.id, original.id);
        expect(modified.url, original.url);
        expect(modified.filePath, original.filePath);
        expect(modified.reciterName, original.reciterName);
        expect(modified.fileSize, original.fileSize);
        expect(modified.downloadedSize, original.downloadedSize);
        expect(modified.createdAt, original.createdAt);
      });

      test('should allow setting completedAt', () {
        // Arrange
        final DownloadItem original = createTestItem();

        // Act
        final DownloadItem modified = original.copyWith(
          completedAt: completedDateTime,
        );

        // Assert
        expect(original.completedAt, isNull);
        expect(modified.completedAt, completedDateTime);
      });

      test('should copy all fields when none specified', () {
        // Arrange
        final DownloadItem original = createTestItem(
          completedAt: completedDateTime,
        );

        // Act
        final DownloadItem copy = original.copyWith();

        // Assert
        expect(copy, equals(original));
        expect(identical(copy, original), isFalse);
      });
    });

    group('Equatable props', () {
      test('two items with same values should be equal', () {
        // Arrange
        final DownloadItem item1 = createTestItem();
        final DownloadItem item2 = createTestItem();

        // Assert
        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('two items with different values should not be equal', () {
        // Arrange
        final DownloadItem item1 = createTestItem(id: 'id1');
        final DownloadItem item2 = createTestItem(id: 'id2');

        // Assert
        expect(item1, isNot(equals(item2)));
      });

      test('equality should consider all props', () {
        final DownloadItem base = createTestItem();

        // Each field change should result in inequality
        expect(base.copyWith(id: 'different'), isNot(equals(base)));
        expect(base.copyWith(title: 'different'), isNot(equals(base)));
        expect(base.copyWith(url: 'different'), isNot(equals(base)));
        expect(base.copyWith(filePath: 'different'), isNot(equals(base)));
        expect(base.copyWith(reciterName: 'different'), isNot(equals(base)));
        expect(
          base.copyWith(status: DownloadStatus.pending),
          isNot(equals(base)),
        );
        expect(base.copyWith(progress: 0.5), isNot(equals(base)));
        expect(base.copyWith(fileSize: 999), isNot(equals(base)));
        expect(base.copyWith(downloadedSize: 999), isNot(equals(base)));
        expect(base.copyWith(createdAt: DateTime(2000)), isNot(equals(base)));
      });
    });
  });

  group('DownloadStatus enum', () {
    test('should have all expected values', () {
      expect(DownloadStatus.values.length, 6);
      expect(DownloadStatus.values, contains(DownloadStatus.pending));
      expect(DownloadStatus.values, contains(DownloadStatus.downloading));
      expect(DownloadStatus.values, contains(DownloadStatus.completed));
      expect(DownloadStatus.values, contains(DownloadStatus.failed));
      expect(DownloadStatus.values, contains(DownloadStatus.paused));
      expect(DownloadStatus.values, contains(DownloadStatus.cancelled));
    });
  });
}
