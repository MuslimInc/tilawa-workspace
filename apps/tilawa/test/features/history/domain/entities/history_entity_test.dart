import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';

void main() {
  final tHistoryEntity = HistoryEntity(
    id: '1',
    surahId: 1,
    surahName: 'Al-Fatihah',
    surahNameEn: 'The Opening',
    reciterId: '1',
    reciterName: 'Mishary Rashid Alafasy',
    moshafId: 1,
    moshafName: 'Hafs',
    lastPositionMs: 0,
    durationMs: 0,
    audioUrl: 'url',
    playedAt: // We will override this in specific tests or use a fixed one
        // Note: const constructor with DateTime is tricky if we want flexible dates.
        // We'll use a constant baseline date.
        // But for timeago logic, we need relative times.
        // So we might construct varied instances in tests.
        // For the const valid check:
        // DateTime.fromMillisecondsSinceEpoch(0) is 1970-01-01.
        // Let's use 0 for simplicity.
        // DateTime.fromMillisecondsSinceEpoch(0) is not a constant for default constructor if we use it directly?
        // Actually DateTime(1970) is const.
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  group('HistoryEntity', () {
    test('duration getter should return Duration from durationMs', () {
      final entity = tHistoryEntity.copyWith(durationMs: 5000);
      expect(entity.duration, const Duration(milliseconds: 5000));
    });

    test('lastPosition getter should return Duration from lastPositionMs', () {
      final entity = tHistoryEntity.copyWith(lastPositionMs: 1000);
      expect(entity.lastPosition, const Duration(milliseconds: 1000));
    });

    test('progress getter should return correct fraction', () {
      final entity = tHistoryEntity.copyWith(
        durationMs: 10000,
        lastPositionMs: 5000,
      );
      expect(entity.progress, 0.5);
    });

    test('progress getter should return 0.0 if duration is 0', () {
      final entity = tHistoryEntity.copyWith(durationMs: 0, lastPositionMs: 0);
      expect(entity.progress, 0.0);
    });

    test('progress getter should return 1.0 when completed', () {
      final entity = tHistoryEntity.copyWith(
        durationMs: 10000,
        lastPositionMs: 0,
        completed: true,
      );
      expect(entity.progress, 1.0);
    });

    test('progress getter should return 1.0 when within 3% of end', () {
      final entity = tHistoryEntity.copyWith(
        durationMs: 10000,
        lastPositionMs: 9700,
      );
      expect(entity.progress, 1.0);
    });

    group('resumeInitialPosition', () {
      test('returns last position for in-progress entry', () {
        final entity = tHistoryEntity.copyWith(
          durationMs: 44834,
          lastPositionMs: 12000,
        );
        expect(
          entity.resumeInitialPosition,
          const Duration(milliseconds: 12000),
        );
      });

      test('returns null when completed so replay starts from beginning', () {
        final entity = tHistoryEntity.copyWith(
          durationMs: 44834,
          lastPositionMs: 44826,
          completed: true,
        );
        expect(entity.resumeInitialPosition, isNull);
      });

      test('returns null when within 3% of end', () {
        final entity = tHistoryEntity.copyWith(
          durationMs: 10000,
          lastPositionMs: 9800,
        );
        expect(entity.resumeInitialPosition, isNull);
      });

      test('returns null when last position is zero', () {
        final entity = tHistoryEntity.copyWith(
          durationMs: 10000,
          lastPositionMs: 0,
        );
        expect(entity.resumeInitialPosition, isNull);
      });
    });

    test('progressPercentage getter should return correct percentage', () {
      final entity = tHistoryEntity.copyWith(
        durationMs: 10000,
        lastPositionMs: 2500,
      );
      expect(entity.progressPercentage, 25.0);
    });

    group('formattedLastPosition', () {
      test('should format mm:ss correctly', () {
        final entity = tHistoryEntity.copyWith(lastPositionMs: 65000); // 1m 5s
        expect(entity.formattedLastPosition, '01:05');
      });

      test('should format hh:mm:ss correctly', () {
        final entity = tHistoryEntity.copyWith(
          lastPositionMs: 3661000,
        ); // 1h 1m 1s
        expect(entity.formattedLastPosition, '01:01:01');
      });
    });

    group('formattedDuration', () {
      test('should format mm:ss correctly', () {
        final entity = tHistoryEntity.copyWith(durationMs: 65000); // 1m 5s
        expect(entity.formattedDuration, '01:05');
      });
    });

    group('formattedPlayedAt', () {
      test('should return "Just now" for < 1 minute', () {
        final now = DateTime.now();
        final entity = tHistoryEntity.copyWith(
          playedAt: now.subtract(const Duration(seconds: 30)),
        );
        expect(entity.formattedPlayedAt, 'Just now');
      });

      test('should return "Xm ago" for < 1 hour', () {
        final now = DateTime.now();
        final entity = tHistoryEntity.copyWith(
          playedAt: now.subtract(const Duration(minutes: 5)),
        );
        expect(entity.formattedPlayedAt, '5m ago');
      });

      test('should return "Xh ago" for < 1 day', () {
        final now = DateTime.now();
        final entity = tHistoryEntity.copyWith(
          playedAt: now.subtract(const Duration(hours: 5)),
        );
        expect(entity.formattedPlayedAt, '5h ago');
      });

      test('should return "Yesterday" for 1 day difference', () {
        final now = DateTime.now();
        final entity = tHistoryEntity.copyWith(
          playedAt: now.subtract(const Duration(days: 1)),
        );
        expect(entity.formattedPlayedAt, 'Yesterday');
      });

      test('should return "Xd ago" for < 7 days', () {
        final now = DateTime.now();
        final entity = tHistoryEntity.copyWith(
          playedAt: now.subtract(const Duration(days: 3)),
        );
        expect(entity.formattedPlayedAt, '3d ago');
      });

      test('should return date string for >= 7 days', () {
        final date = DateTime(2023, 1, 1);
        final entity = tHistoryEntity.copyWith(playedAt: date);
        expect(entity.formattedPlayedAt, '1/1/2023');
      });
    });

    group('getFormattedPlayedAt (localized)', () {
      String localizer(String key) {
        const map = {
          'justNow': 'Just Now',
          'minutesAgo': '{count}m ago',
          'hoursAgo': '{count}h ago',
          'yesterday': 'Yest',
          'daysAgo': '{count}d ago',
        };
        return map[key] ?? key;
      }

      test('should use localizer correctly', () {
        final now = DateTime.now();
        final entity = tHistoryEntity.copyWith(
          playedAt: now.subtract(const Duration(minutes: 5)),
        );
        expect(entity.getFormattedPlayedAt(localizer), '5m ago');
      });
    });
  });
}
