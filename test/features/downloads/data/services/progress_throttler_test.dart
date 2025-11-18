import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';

void main() {
  group('ProgressThrottler', () {
    late ProgressThrottler throttler;

    setUp(() {
      throttler = ProgressThrottler();
    });

    group('shouldSendUpdate', () {
      test('should always send initial update (received == 0)', () {
        // Arrange
        const received = 0;
        const total = 1000;
        const progress = 0.0;

        // Act
        final shouldSend = throttler.shouldSendUpdate(
          received: received,
          total: total,
          progress: progress,
        );

        // Assert
        expect(
          shouldSend,
          true,
          reason: 'Initial update should always be sent',
        );
      });

      test('should always send final update (received == total)', () {
        // Arrange
        const received = 1000;
        const total = 1000;
        const progress = 1.0;

        // Act
        final shouldSend = throttler.shouldSendUpdate(
          received: received,
          total: total,
          progress: progress,
        );

        // Assert
        expect(shouldSend, true, reason: 'Final update should always be sent');
      });

      test('should send update when progress changes by 1% or more', () {
        // Arrange
        throttler.recordUpdate(received: 0);

        // Act - Progress changes by 1% (10 bytes out of 1000)
        final shouldSend = throttler.shouldSendUpdate(
          received: 10,
          total: 1000,
          progress: 0.01,
        );

        // Assert
        expect(shouldSend, true, reason: '1% change should trigger update');
      });

      test('should not send update when progress changes by less than 1%', () {
        // Arrange
        throttler.recordUpdate(received: 0);

        // Act - Progress changes by 0.5% (5 bytes out of 1000)
        final shouldSend = throttler.shouldSendUpdate(
          received: 5,
          total: 1000,
          progress: 0.005,
        );

        // Assert
        expect(
          shouldSend,
          false,
          reason: 'Less than 1% change should not trigger update',
        );
      });

      test('should send update after 100ms has passed', () async {
        // Arrange
        throttler.recordUpdate(received: 0);

        // Act - Wait 100ms
        await Future.delayed(const Duration(milliseconds: 110));

        final shouldSend = throttler.shouldSendUpdate(
          received: 5, // Small change (< 1%)
          total: 1000,
          progress: 0.005,
        );

        // Assert
        expect(shouldSend, true, reason: 'Update should be sent after 100ms');
      });

      test(
        'should not send update if less than 100ms and less than 1% change',
        () async {
          // Arrange
          throttler.recordUpdate(received: 0);

          // Act - Wait only 50ms
          await Future.delayed(const Duration(milliseconds: 50));

          final shouldSend = throttler.shouldSendUpdate(
            received: 5, // Small change (< 1%)
            total: 1000,
            progress: 0.005,
          );

          // Assert
          expect(
            shouldSend,
            false,
            reason: 'Update should not be sent if < 100ms and < 1% change',
          );
        },
      );

      test('should track progress updates correctly', () {
        // Arrange & Act
        throttler.recordUpdate(received: 100);

        // Verify next update calculation
        final shouldSend = throttler.shouldSendUpdate(
          received: 200, // 100 bytes more = 10% of 1000
          total: 1000,
          progress: 0.2,
        );

        // Assert
        expect(shouldSend, true, reason: '10% change should trigger update');
      });

      test('should handle large file sizes correctly', () {
        // Arrange
        throttler.recordUpdate(received: 0);
        const largeTotal = 10000000; // 10MB

        // Act - 1% of 10MB = 100KB
        final shouldSend = throttler.shouldSendUpdate(
          received: 100000, // 1% of 10MB
          total: largeTotal,
          progress: 0.01,
        );

        // Assert
        expect(
          shouldSend,
          true,
          reason: '1% of large file should trigger update',
        );
      });

      test('should handle rapid progress updates with throttling', () async {
        // Arrange
        final updatesSent = <int>[];
        int received = 0;
        const total = 1000;

        // Simulate rapid progress updates (every 10ms with 0.5% increments)
        // This tests time-based throttling since each change is < 1%
        for (int i = 0; i < 20; i++) {
          received += 5; // 0.5% per update (< 1% threshold)
          final progress = received / total;

          if (throttler.shouldSendUpdate(
            received: received,
            total: total,
            progress: progress,
          )) {
            updatesSent.add(received);
            throttler.recordUpdate(received: received);
          }

          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Assert
        print('📊 Updates sent: $updatesSent');
        print('📊 Total updates: ${updatesSent.length}');
        // Should be throttled - not all 20 updates should be sent
        // Because each change is < 1%, time-based throttling (100ms) applies
        expect(updatesSent.length, greaterThan(1));
        expect(
          updatesSent.length,
          lessThan(20),
          reason: 'Updates with < 1% change should be throttled by time',
        );
      });
    });

    group('shouldSendUpdateUnknownSize', () {
      test('should always send initial update (received == 0)', () {
        // Act
        final shouldSend = throttler.shouldSendUpdateUnknownSize(received: 0);

        // Assert
        expect(
          shouldSend,
          true,
          reason: 'Initial update should always be sent',
        );
      });

      test('should send update after 100ms has passed', () async {
        // Arrange
        throttler.recordUpdate(received: 0);

        // Act - Wait 100ms
        await Future.delayed(const Duration(milliseconds: 110));

        final shouldSend = throttler.shouldSendUpdateUnknownSize(received: 100);

        // Assert
        expect(shouldSend, true, reason: 'Update should be sent after 100ms');
      });

      test('should not send update if less than 100ms', () async {
        // Arrange
        throttler.recordUpdate(received: 0);

        // Act - Wait only 50ms
        await Future.delayed(const Duration(milliseconds: 50));

        final shouldSend = throttler.shouldSendUpdateUnknownSize(received: 100);

        // Assert
        expect(
          shouldSend,
          false,
          reason: 'Update should not be sent if < 100ms',
        );
      });

      test('should throttle updates to at most every 100ms', () async {
        // Arrange
        final updatesSent = <int>[];

        // Simulate rapid progress updates (every 10ms)
        for (int i = 0; i < 20; i++) {
          final received = i * 10;

          if (throttler.shouldSendUpdateUnknownSize(received: received)) {
            updatesSent.add(received);
            throttler.recordUpdate(received: received);
          }

          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Assert
        print('📊 Unknown size updates sent: $updatesSent');
        print('📊 Total updates: ${updatesSent.length}');
        // Should be throttled - not all 20 updates should be sent
        expect(updatesSent.length, greaterThan(1));
        expect(
          updatesSent.length,
          lessThan(20),
          reason: 'Updates should be throttled',
        );
      });
    });

    group('recordUpdate', () {
      test('should update internal state correctly', () {
        // Act
        throttler.recordUpdate(received: 500);

        // Verify state was updated by checking next update
        final shouldSend = throttler.shouldSendUpdate(
          received: 600, // 100 bytes more = 10% of 1000
          total: 1000,
          progress: 0.6,
        );

        // Assert
        expect(shouldSend, true, reason: 'State should be updated correctly');
      });

      test('should update timestamp correctly', () async {
        // Arrange
        throttler.recordUpdate(received: 100);

        // Act - Wait less than 100ms
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify timestamp was updated - check with small progress change (< 1%)
        final shouldSend = throttler.shouldSendUpdate(
          received: 105, // 5 bytes = 0.5% of 1000 (< 1% threshold)
          total: 1000,
          progress: 0.105,
        );

        // Assert
        // Should not send because < 100ms has passed and < 1% change
        // Note: Due to timing precision, this might occasionally pass
        // The important thing is that time-based throttling is working
        expect(
          shouldSend,
          false,
          reason:
              'Timestamp should prevent immediate update when < 100ms and < 1% change',
        );
      });
    });

    group('reset', () {
      test('should reset internal state', () {
        // Arrange
        throttler.recordUpdate(received: 500);

        // Act
        throttler.reset();

        // Assert - After reset, initial update should be allowed
        final shouldSend = throttler.shouldSendUpdate(
          received: 0,
          total: 1000,
          progress: 0.0,
        );
        expect(
          shouldSend,
          true,
          reason: 'After reset, should allow initial update',
        );
      });

      test('should allow new updates after reset', () {
        // Arrange
        throttler.recordUpdate(received: 500);
        throttler.reset();

        // Act
        final shouldSend = throttler.shouldSendUpdate(
          received: 100,
          total: 1000,
          progress: 0.1,
        );

        // Assert
        expect(
          shouldSend,
          true,
          reason: 'After reset, should allow new updates',
        );
      });
    });

    group('Real-Time Progress Simulation', () {
      test('should throttle progress updates simulating real download', () async {
        // This test simulates a real download scenario with progress updates
        // Arrange
        final progressUpdates = <Map<String, dynamic>>[];
        const totalBytes = 10000;
        int receivedBytes = 0;

        print('📥 Simulating download: 0% -> 100%');

        // Act - Simulate download progress every 10ms
        for (int i = 0; i <= 100; i++) {
          receivedBytes = (totalBytes * i / 100).round();
          final progress = receivedBytes / totalBytes;

          if (throttler.shouldSendUpdate(
            received: receivedBytes,
            total: totalBytes,
            progress: progress,
          )) {
            progressUpdates.add({
              'received': receivedBytes,
              'progress': progress,
              'percentage': (progress * 100).round(),
            });
            throttler.recordUpdate(received: receivedBytes);
            print(
              '⏱️  Update ${progressUpdates.length}: ${(progress * 100).toStringAsFixed(1)}% ($receivedBytes/$totalBytes bytes)',
            );
          }

          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Assert
        print('📊 Total progress updates sent: ${progressUpdates.length}');
        print('📊 Expected without throttling: 101');
        if (progressUpdates.length < 101) {
          print(
            '📊 Throttling efficiency: ${((1 - progressUpdates.length / 101) * 100).toStringAsFixed(1)}% reduction',
          );
        }

        // Should have sent updates
        // Note: If progress changes by >= 1% each time, all updates will be sent
        // Time-based throttling only applies when progress change is < 1%
        expect(progressUpdates.length, greaterThan(10));
        // In this test, we're simulating 1% increments every 10ms
        // Since each increment is >= 1%, all updates should be sent
        // But if time-based throttling kicks in, some might be skipped
        expect(progressUpdates.length, greaterThanOrEqualTo(10));

        // Verify progress increases
        for (int i = 1; i < progressUpdates.length; i++) {
          expect(
            progressUpdates[i]['progress'],
            greaterThanOrEqualTo(progressUpdates[i - 1]['progress']),
            reason: 'Progress should be non-decreasing',
          );
        }

        // Verify initial and final updates were sent
        expect(progressUpdates.first['received'], 0);
        expect(progressUpdates.last['received'], totalBytes);
      });

      test('should handle 1% progress increments correctly', () {
        // Arrange
        const totalBytes = 1000;
        final updatesSent = <int>[];

        // Act - Simulate 1% increments (without time delays)
        // Each increment changes progress by exactly 1%, so all should be sent
        for (int percent = 0; percent <= 100; percent++) {
          final received = (totalBytes * percent / 100).round();
          final progress = received / totalBytes;

          if (throttler.shouldSendUpdate(
            received: received,
            total: totalBytes,
            progress: progress,
          )) {
            updatesSent.add(percent);
            throttler.recordUpdate(received: received);
          }
        }

        // Assert
        print('📊 Updates sent for 1% increments: $updatesSent');
        // When progress changes by exactly 1% each time, all updates should be sent
        // because the 1% change threshold is met
        expect(
          updatesSent.length,
          101,
          reason: 'All 1% increments should trigger updates (0% to 100%)',
        );
        expect(updatesSent.first, 0, reason: 'Should send initial update');
        expect(updatesSent.last, 100, reason: 'Should send final update');
      });

      test('should throttle when progress changes by less than 1%', () async {
        // Arrange
        const totalBytes = 10000; // Larger file to test small increments
        final updatesSent = <int>[];

        // Act - Simulate 0.1% increments (1/1000 of total) with time delays
        // This tests that time-based throttling works for small progress changes
        for (int increment = 0; increment <= 1000; increment++) {
          final received = (totalBytes * increment / 1000)
              .round(); // 0.1% per increment
          final progress = received / totalBytes;

          if (throttler.shouldSendUpdate(
            received: received,
            total: totalBytes,
            progress: progress,
          )) {
            updatesSent.add(increment);
            throttler.recordUpdate(received: received);
          }

          // Add small delay to allow time-based throttling to work
          await Future.delayed(const Duration(milliseconds: 2));
        }

        // Assert
        print('📊 Updates sent for 0.1% increments: ${updatesSent.length}');
        print('📊 Expected without throttling: 1001');
        // When progress changes by 0.1% increments, updates will be sent when:
        // 1. Initial (0%)
        // 2. Every 1% change accumulates (every 10 increments = 1%)
        // 3. Final (100%)
        // So we expect roughly 101 updates (0%, 1%, 2%, ..., 100%)
        // This is much less than 1001, showing throttling is working
        expect(
          updatesSent.length,
          lessThan(1001),
          reason:
              'Updates with < 1% change should be throttled (only 1% increments trigger updates)',
        );
        expect(
          updatesSent.length,
          greaterThan(50),
          reason:
              'Should send updates for each 1% increment (roughly 101 updates)',
        );
        expect(updatesSent.first, 0, reason: 'Should send initial update');
        expect(updatesSent.last, 1000, reason: 'Should send final update');
      });
    });
  });
}
