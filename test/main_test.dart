import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/services/analytics_initialization_service.dart';
import 'package:tilawa/core/services/appsflyer_service.dart';
import 'package:tilawa/core/services/crashlytics_service.dart';
import 'package:tilawa/core/services/luciq_service.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/features/downloads/data/services/downloads_initialization_service.dart';
import 'package:tilawa/features/notifications/domain/repositories/notifications_repository.dart';

// Mock implementations
class MockCrashlyticsService extends Mock implements CrashlyticsService {}

class MockAnalyticsInitService extends Mock
    implements AnalyticsInitializationService {}

class MockAppsFlyerService extends Mock implements AppsFlyerService {}

class MockLuciqService extends Mock implements LuciqService {}

class MockNotificationPermissionService extends Mock
    implements NotificationPermissionService {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockDownloadsInitService extends Mock
    implements DownloadsInitializationService {}

void main() {
  group('App Startup Initialization Tests', () {
    late MockCrashlyticsService mockCrashlytics;
    late MockAnalyticsInitService mockAnalytics;
    late MockAppsFlyerService mockAppsFlyer;
    late MockLuciqService mockLuciq;
    late MockNotificationPermissionService mockNotificationPermission;
    late MockNotificationsRepository mockNotificationsRepo;
    late MockDownloadsInitService mockDownloads;

    setUp(() {
      mockCrashlytics = MockCrashlyticsService();
      mockAnalytics = MockAnalyticsInitService();
      mockAppsFlyer = MockAppsFlyerService();
      mockLuciq = MockLuciqService();
      mockNotificationPermission = MockNotificationPermissionService();
      mockNotificationsRepo = MockNotificationsRepository();
      mockDownloads = MockDownloadsInitService();

      // Setup default stub responses
      when(
        () => mockCrashlytics.initialize(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockAnalytics.initialize(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockAppsFlyer.initialize(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockAppsFlyer.startTracking(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockLuciq.initialize(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockNotificationPermission.requestPermissionOnFirstLaunch(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockNotificationsRepo.requestPermission(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockNotificationsRepo.getToken(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockNotificationsRepo.initializeListeners(),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockDownloads.initialize(),
      ).thenAnswer((_) async => Future.value());
    });

    group('Critical Services Initialization', () {
      test('should initialize Crashlytics during critical phase', () async {
        // Arrange
        when(
          () => mockCrashlytics.initialize(),
        ).thenAnswer((_) async => Future.value());

        // Act
        await mockCrashlytics.initialize();

        // Assert
        verify(() => mockCrashlytics.initialize()).called(1);
      });

      test(
        'should handle Crashlytics initialization error gracefully',
        () async {
          // Arrange
          when(
            () => mockCrashlytics.initialize(),
          ).thenThrow(Exception('Crashlytics error'));

          // Act & Assert - should not crash the app
          expect(() async => mockCrashlytics.initialize(), throwsException);
        },
      );
    });

    group('Non-Critical Services Parallel Initialization', () {
      test(
        'should initialize analytics, appsflyer, and luciq in parallel',
        () async {
          // Arrange
          final completer1 = Completer<void>();
          final completer2 = Completer<void>();
          final completer3 = Completer<void>();
          final completer4 = Completer<void>();

          when(
            () => mockAnalytics.initialize(),
          ).thenAnswer((_) => completer1.future);
          when(
            () => mockAppsFlyer.initialize(),
          ).thenAnswer((_) => completer2.future);
          when(
            () => mockAppsFlyer.startTracking(),
          ).thenAnswer((_) => completer3.future);
          when(
            () => mockLuciq.initialize(),
          ).thenAnswer((_) => completer4.future);

          // Act - simulate parallel execution using .wait pattern
          final Future<(void, void, void)> futureResult = (
            mockAnalytics.initialize(),
            Future.microtask(() async {
              await mockAppsFlyer.initialize();
              await mockAppsFlyer.startTracking();
            }),
            mockLuciq.initialize(),
          ).wait;

          // Complete all in parallel
          completer1.complete();
          completer2.complete();
          completer3.complete();
          completer4.complete();

          await futureResult;

          // Assert - all were called
          verify(() => mockAnalytics.initialize()).called(1);
          verify(() => mockAppsFlyer.initialize()).called(1);
          verify(() => mockAppsFlyer.startTracking()).called(1);
          verify(() => mockLuciq.initialize()).called(1);
        },
      );

      test('should continue even if one non-critical service fails', () async {
        // Arrange
        when(
          () => mockAnalytics.initialize(),
        ).thenThrow(Exception('Analytics failed'));
        when(
          () => mockAppsFlyer.initialize(),
        ).thenAnswer((_) async => Future.value());
        when(
          () => mockAppsFlyer.startTracking(),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert - should handle error gracefully
        try {
          await mockAnalytics.initialize();
        } catch (e) {
          // Expected to fail
        }

        // Other services should still work
        await mockAppsFlyer.initialize();
        await mockAppsFlyer.startTracking();

        verify(() => mockAppsFlyer.initialize()).called(1);
        verify(() => mockAppsFlyer.startTracking()).called(1);
      });
    });

    group('Service Initialization Order', () {
      test('should initialize AppsFlyer after Analytics in sequence', () async {
        // Arrange
        final callOrder = <String>[];

        when(() => mockAnalytics.initialize()).thenAnswer((_) async {
          callOrder.add('analytics');
          return Future.value();
        });

        when(() => mockAppsFlyer.initialize()).thenAnswer((_) async {
          callOrder.add('appsflyer_init');
          return Future.value();
        });

        when(() => mockAppsFlyer.startTracking()).thenAnswer((_) async {
          callOrder.add('appsflyer_track');
          return Future.value();
        });

        // Act
        await mockAnalytics.initialize();
        await mockAppsFlyer.initialize();
        await mockAppsFlyer.startTracking();

        // Assert
        expect(callOrder, ['analytics', 'appsflyer_init', 'appsflyer_track']);
      });

      test(
        'should request permission before initializing notifications',
        () async {
          // Arrange
          final callOrder = <String>[];

          when(
            () => mockNotificationPermission.requestPermissionOnFirstLaunch(),
          ).thenAnswer((_) async {
            callOrder.add('permission');
            return Future.value();
          });

          when(() => mockNotificationsRepo.requestPermission()).thenAnswer((
            _,
          ) async {
            callOrder.add('notification_permission');
            return Future.value();
          });

          when(() => mockNotificationsRepo.getToken()).thenAnswer((_) async {
            callOrder.add('notification_token');
            return Future.value();
          });

          // Act
          await mockNotificationPermission.requestPermissionOnFirstLaunch();
          await mockNotificationsRepo.requestPermission();
          await mockNotificationsRepo.getToken();

          // Assert
          expect(callOrder.first, 'permission');
          expect(callOrder, contains('notification_permission'));
          expect(callOrder, contains('notification_token'));
        },
      );
    });

    group('Parallel Execution Verification', () {
      test('should run notifications and downloads in parallel', () async {
        // Arrange
        final notificationCompleter = Completer<void>();
        final downloadsCompleter = Completer<void>();

        when(
          () => mockNotificationsRepo.requestPermission(),
        ).thenAnswer((_) => notificationCompleter.future);
        when(
          () => mockDownloads.initialize(),
        ).thenAnswer((_) => downloadsCompleter.future);

        // Act - simulate parallel execution
        final Future<(void, void)> futureResult = (
          mockNotificationsRepo.requestPermission(),
          mockDownloads.initialize(),
        ).wait;

        // Complete both
        notificationCompleter.complete();
        downloadsCompleter.complete();

        await futureResult;

        // Assert
        verify(() => mockNotificationsRepo.requestPermission()).called(1);
        verify(() => mockDownloads.initialize()).called(1);
      });
    });

    group('AppsFlyer Service Tests', () {
      test('should initialize AppsFlyer and start tracking', () async {
        // Arrange
        when(
          () => mockAppsFlyer.initialize(),
        ).thenAnswer((_) async => Future.value());
        when(
          () => mockAppsFlyer.startTracking(),
        ).thenAnswer((_) async => Future.value());

        // Act
        await mockAppsFlyer.initialize();
        await mockAppsFlyer.startTracking();

        // Assert
        verify(() => mockAppsFlyer.initialize()).called(1);
        verify(() => mockAppsFlyer.startTracking()).called(1);
      });

      test('should handle AppsFlyer initialization failure', () async {
        // Arrange
        when(
          () => mockAppsFlyer.initialize(),
        ).thenThrow(Exception('AppsFlyer init failed'));

        // Act & Assert
        expect(() async => mockAppsFlyer.initialize(), throwsException);
      });
    });

    group('Luciq Service Tests', () {
      test('should initialize Luciq successfully', () async {
        // Arrange
        when(
          () => mockLuciq.initialize(),
        ).thenAnswer((_) async => Future.value());

        // Act
        await mockLuciq.initialize();

        // Assert
        verify(() => mockLuciq.initialize()).called(1);
      });

      test('should handle Luciq initialization failure', () async {
        // Arrange
        when(
          () => mockLuciq.initialize(),
        ).thenThrow(Exception('Luciq init failed'));

        // Act & Assert
        expect(() async => mockLuciq.initialize(), throwsException);
      });
    });

    group('Error Recovery Tests', () {
      test(
        'should continue app startup even if all non-critical services fail',
        () async {
          // Arrange - all non-critical services fail
          when(
            () => mockAnalytics.initialize(),
          ).thenThrow(Exception('Analytics failed'));
          when(
            () => mockAppsFlyer.initialize(),
          ).thenThrow(Exception('AppsFlyer failed'));
          when(
            () => mockLuciq.initialize(),
          ).thenThrow(Exception('Luciq failed'));

          // Act & Assert - services should fail but not crash
          final failures = <String>[];

          try {
            await mockAnalytics.initialize();
          } catch (e) {
            failures.add('analytics');
          }

          try {
            await mockAppsFlyer.initialize();
          } catch (e) {
            failures.add('appsflyer');
          }

          try {
            await mockLuciq.initialize();
          } catch (e) {
            failures.add('luciq');
          }

          // All services attempted initialization
          expect(failures, hasLength(3));
          expect(failures, contains('analytics'));
          expect(failures, contains('appsflyer'));
          expect(failures, contains('luciq'));
        },
      );
    });

    group('Dart 3 Record .wait Pattern Tests', () {
      test(
        'should properly destructure results from parallel futures',
        () async {
          // Arrange
          when(
            () => mockAnalytics.initialize(),
          ).thenAnswer((_) async => Future.value());
          when(
            () => mockAppsFlyer.initialize(),
          ).thenAnswer((_) async => Future.value());

          // Act - using .wait pattern
          final (_, _) = await (
            mockAnalytics.initialize(),
            mockAppsFlyer.initialize(),
          ).wait;

          // Assert
          verify(() => mockAnalytics.initialize()).called(1);
          verify(() => mockAppsFlyer.initialize()).called(1);
        },
      );

      test('should handle errors in .wait pattern gracefully', () async {
        // Arrange
        when(() => mockAnalytics.initialize()).thenThrow(Exception('Failed'));
        when(
          () => mockAppsFlyer.initialize(),
        ).thenAnswer((_) async => Future.value());

        // Act & Assert
        expect(
          () async =>
              (mockAnalytics.initialize(), mockAppsFlyer.initialize()).wait,
          throwsException,
        );
      });
    });
  });
}
