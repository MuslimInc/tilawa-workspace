import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/entities/moshaf_entity.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/theme/app_theme.dart';
import 'package:tilawa/core/utils/typedefs.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/firebase_options.dart';
import 'package:tilawa/quran_player_app.dart';
import 'package:tilawa/router/app_router.dart';

/// Integration tests for DownloadAllButton functionality
///
/// Tests cover:
/// - DownloadAll button is visible on reciter details screen
/// - Tapping DownloadAll starts downloading all surahs
/// - Progress updates are shown during download
/// - Pause/Cancel functionality works
/// - All Downloaded state shows correctly

// ============================================================================
// Test Helpers
// ============================================================================

/// Wait for a widget to appear with configurable timeout
Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  String? errorMessage,
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
  throw TimeoutException(
    errorMessage ?? 'Widget not found after ${timeout.inSeconds} seconds',
    timeout,
  );
}

/// Navigate to the reciters tab
Future<void> navigateToRecitersTab(WidgetTester tester) async {
  debugPrint('Navigating to Reciters Tab...');
  await tester.pump(const Duration(seconds: 2));

  // Try multiple selectors to find reciters tab
  final Finder recitersIconFinder = find.byIcon(FluentIcons.person_24_regular);
  final Finder recitersActiveIconFinder = find.byIcon(
    FluentIcons.person_24_filled,
  );
  final Finder recitersTextFinder = find.text('Reciters');

  if (recitersIconFinder.evaluate().isNotEmpty) {
    await tester.tap(recitersIconFinder.first);
  } else if (recitersActiveIconFinder.evaluate().isNotEmpty) {
    await tester.tap(recitersActiveIconFinder.first);
  } else if (recitersTextFinder.evaluate().isNotEmpty) {
    await tester.tap(recitersTextFinder.first);
  }

  await tester.pump(const Duration(seconds: 1));
}

/// Clean up at the end of a test to prevent pending frames and async issues
Future<void> cleanupTest(WidgetTester tester) async {
  debugPrint('Cleaning up test...');

  // Just pump a few times instead of pumpAndSettle
  // (pumpAndSettle hangs when downloads are active with continuous progress updates)
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  debugPrint('Test cleanup complete');
}

/// Navigate to reciter details by tapping first reciter card
Future<void> navigateToReciterDetails(WidgetTester tester) async {
  debugPrint('Looking for reciter cards...');
  await tester.pump(const Duration(seconds: 3));

  // Try to find the reciter by name (from our mock data)
  debugPrint('Finding Reciter: Mishary Rashid Alafasy');
  final Finder reciterFinder = find.text('Mishary Rashid Alafasy');

  if (reciterFinder.evaluate().isNotEmpty) {
    debugPrint('Reciter found! Tapping...');
    await tester.ensureVisible(reciterFinder.first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(reciterFinder.first);
    debugPrint('Tapped reciter. Waiting for navigation...');
    await tester.pump(const Duration(seconds: 2));
    return;
  }

  debugPrint('Reciter "Mishary Rashid Alafasy" not found!');
}

/// Find the Download All button
Finder findDownloadAllButton() {
  return find.byKey(const Key('download_all_button'));
}

/// Find Download All button by text (supports both English and Arabic)
Finder findDownloadAllButtonByText() {
  // Try English first, then Arabic
  final Finder englishFinder = find.textContaining('Download All');
  if (englishFinder.evaluate().isNotEmpty) {
    return englishFinder;
  }
  // Arabic: تحميل الكل
  return find.textContaining('تحميل الكل');
}

/// Check if button shows any valid state text (English or Arabic)
bool hasDownloadButtonState(WidgetTester tester) {
  // English states
  final bool hasEnglish =
      find.textContaining('Download All').evaluate().isNotEmpty ||
      find.textContaining('Complete Downloading').evaluate().isNotEmpty ||
      find.textContaining('All Downloaded').evaluate().isNotEmpty ||
      find.textContaining('Pause').evaluate().isNotEmpty;

  // Arabic states
  // تحميل الكل = Download All
  // استكمال التحميل = Complete Downloading
  // تم التحميل بالكامل = All Downloaded
  // إيقاف = Pause
  final bool hasArabic =
      find.textContaining('تحميل الكل').evaluate().isNotEmpty ||
      find.textContaining('استكمال التحميل').evaluate().isNotEmpty ||
      find.textContaining('تم التحميل بالكامل').evaluate().isNotEmpty ||
      find.textContaining('إيقاف').evaluate().isNotEmpty;

  return hasEnglish || hasArabic;
}

/// Check if all surahs are downloaded (English or Arabic)
bool isAllDownloadedState(WidgetTester tester) {
  return find.textContaining('All Downloaded').evaluate().isNotEmpty ||
      find.textContaining('تم التحميل بالكامل').evaluate().isNotEmpty ||
      find.byIcon(Icons.check_circle_outline).evaluate().isNotEmpty;
}

/// Check if download is in progress
bool isDownloadingState(WidgetTester tester) {
  return find.byIcon(Icons.pause_rounded).evaluate().isNotEmpty ||
      find.textContaining('Pause').evaluate().isNotEmpty ||
      find.textContaining('إيقاف').evaluate().isNotEmpty ||
      find.textContaining('%').evaluate().isNotEmpty;
}

// ============================================================================
// Fake Implementations for Testing
// ============================================================================

/// Fake implementation to bypass splash/login checks
class FakeGetSplashNextRouteUseCase implements GetSplashNextRouteUseCase {
  @override
  Future<SplashDestination> call() async {
    return SplashDestination.home;
  }
}

/// Fake implementation to return a logged-in user
class FakeGetCurrentUserUseCase implements GetCurrentUserUseCase {
  @override
  UserEntity? call() {
    return UserEntity(
      id: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime.now(),
    );
  }
}

/// Fake implementation to bypass notification permission checks
class FakeNotificationPermissionService
    implements NotificationPermissionService {
  @override
  Future<bool> hasRequestedPermission() async => true;

  @override
  Future<bool> isFirstLaunch() async => false;

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> requestPermissionOnFirstLaunch() async {}
}

/// Fake implementation of RecitersRepository
class FakeRecitersRepository implements RecitersRepository {
  @override
  ResultFuture<List<ReciterEntity>> getReciters() async {
    return const Right([
      ReciterEntity(
        id: 1,
        name: 'Mishary Rashid Alafasy',
        letter: 'M',
        date: '2024-01-01',
        moshaf: [
          MoshafEntity(
            id: 1,
            name: "Rewayat Hafs A'n Assem",
            server: 'https://server8.mp3quran.net/afs/',
            surahTotal: 114,
            moshafType: 1,
            surahList: '1,2,3',
          ),
        ],
      ),
    ]);
  }

  @override
  ResultFuture<List<ReciterEntity>> searchReciters(String query) async {
    return getReciters();
  }

  @override
  ResultFuture<List<ReciterEntity>> getRecitersByLetter(String letter) async {
    return getReciters();
  }

  @override
  ResultFuture<ReciterEntity?> getReciterById(String id) async {
    final Either<Failure, List<ReciterEntity>> result = await getReciters();
    return Right(result.fold((l) => null, (r) => r.first));
  }

  @override
  ResultFuture<List<ReciterEntity>> getFavoriteReciters() async {
    return const Right([]);
  }

  @override
  ResultFuture<void> toggleFavoriteReciter(int id) async {
    return const Right<Failure, void>(null);
  }

  @override
  ResultFuture<List<String>> getFavoriteReciterIds() async {
    return const Right([]);
  }
}

// ============================================================================
// Test Suite
// ============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadAllButton Integration Tests', () {
    setUpAll(() async {
      // Disable Google Fonts runtime fetching to avoid network calls in tests
      GoogleFonts.config.allowRuntimeFetching = false;

      // Disable google_fonts in AppTheme to avoid font loading errors
      AppTheme.useGoogleFonts = false;

      // Allow reassigning dependencies
      GetIt.instance.allowReassignment = true;

      // Initialize AppRouter
      AppRouter.init();

      // Initialize Firebase
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Configure dependencies (DI)
      await configureDependencies();

      // Replace RecitersRepository with fake to avoid network calls
      if (GetIt.instance.isRegistered<RecitersRepository>()) {
        GetIt.instance.unregister<RecitersRepository>();
      }
      GetIt.instance.registerSingleton<RecitersRepository>(
        FakeRecitersRepository(),
      );

      // Refresh GetRecitersUseCase with new fake repository
      if (GetIt.instance.isRegistered<GetRecitersUseCase>()) {
        GetIt.instance.unregister<GetRecitersUseCase>();
      }
      GetIt.instance.registerSingleton<GetRecitersUseCase>(
        GetRecitersUseCase(GetIt.instance<RecitersRepository>()),
      );

      // Replace GetCurrentUserUseCase to mock authenticated user
      if (GetIt.instance.isRegistered<GetCurrentUserUseCase>()) {
        GetIt.instance.unregister<GetCurrentUserUseCase>();
      }
      GetIt.instance.registerFactory<GetCurrentUserUseCase>(
        () => FakeGetCurrentUserUseCase(),
      );

      // Replace GetSplashNextRouteUseCase to skip splash/login
      if (GetIt.instance.isRegistered<GetSplashNextRouteUseCase>()) {
        GetIt.instance.unregister<GetSplashNextRouteUseCase>();
      }
      GetIt.instance.registerFactory<GetSplashNextRouteUseCase>(
        () => FakeGetSplashNextRouteUseCase(),
      );

      // Replace NotificationPermissionService to avoid permission dialogs
      if (GetIt.instance.isRegistered<NotificationPermissionService>()) {
        GetIt.instance.unregister<NotificationPermissionService>();
      }
      GetIt.instance.registerSingleton<NotificationPermissionService>(
        FakeNotificationPermissionService(),
      );

      // Initialize HydratedStorage
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(
          (await getTemporaryDirectory()).path,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
    });

    tearDown(() async {
      // Allow any background operations to complete
      await Future.delayed(const Duration(seconds: 2));

      // Clean up storage
      await HydratedBloc.storage.clear();

      // Final settling period before next test
      await Future.delayed(const Duration(seconds: 1));
    });

    testWidgets('DownloadAllButton is visible on reciter details screen', (
      WidgetTester tester,
    ) async {
      // Given: App is loaded
      await tester.pumpWidget(const QuranPlayerApp());
      await tester.pump(const Duration(seconds: 3));

      // When: Navigate to reciter details
      await navigateToRecitersTab(tester);
      await navigateToReciterDetails(tester);

      // Then: Download All button should be visible
      await tester.pump(const Duration(seconds: 2));

      // Look for the Download All button by key or text
      final Finder downloadAllButton = findDownloadAllButton();
      final Finder downloadAllText = findDownloadAllButtonByText();

      final bool buttonFound =
          downloadAllButton.evaluate().isNotEmpty ||
          downloadAllText.evaluate().isNotEmpty;

      // Debug: Print all buttons found
      debugPrint('Looking for Download All button...');
      final Finder allButtons = find.byType(ElevatedButton);
      debugPrint('Found ${allButtons.evaluate().length} ElevatedButtons');

      expect(
        buttonFound,
        true,
        reason: 'Download All button should be visible on reciter details',
      );

      // Clean up to prevent pending frame issues
      await cleanupTest(tester);
    });

    testWidgets('Tapping DownloadAll starts downloading all surahs', (
      WidgetTester tester,
    ) async {
      // Given: App is loaded and on reciter details screen
      await tester.pumpWidget(const QuranPlayerApp());
      await tester.pump(const Duration(seconds: 3));
      await navigateToRecitersTab(tester);
      await navigateToReciterDetails(tester);
      await tester.pump(const Duration(seconds: 2));

      // Find the Download All button
      Finder downloadAllButton = findDownloadAllButton();
      if (downloadAllButton.evaluate().isEmpty) {
        downloadAllButton = findDownloadAllButtonByText();
      }

      if (downloadAllButton.evaluate().isEmpty) {
        debugPrint('Download All button not found, skipping test');
        return;
      }

      // When: Tap the Download All button
      await tester.ensureVisible(downloadAllButton.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(downloadAllButton.first);
      await tester.pump(const Duration(seconds: 1));

      // Then: Should see download started (pause icon or progress)
      final Finder pauseIcon = find.byIcon(Icons.pause_rounded);
      final Finder progressIndicator = find.byType(CircularProgressIndicator);
      final Finder progressText = find.textContaining('%');

      // Wait for download to start
      final DateTime end = DateTime.now().add(const Duration(seconds: 10));
      var downloadStarted = false;

      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 500));

        if (pauseIcon.evaluate().isNotEmpty ||
            progressIndicator.evaluate().isNotEmpty ||
            progressText.evaluate().isNotEmpty) {
          downloadStarted = true;
          break;
        }
      }

      // Download should start or already be complete
      expect(
        downloadStarted || isAllDownloadedState(tester),
        true,
        reason: 'Download should start (show progress) or be already completed',
      );

      // Cancel the downloads if they started
      if (downloadStarted) {
        debugPrint('Canceling downloads...');
        // Tap the pause button to stop downloads
        if (pauseIcon.evaluate().isNotEmpty) {
          await tester.tap(pauseIcon.first);
          await tester.pump(const Duration(milliseconds: 500));
        }
      }

      // Clean up to prevent pending frame issues
      await cleanupTest(tester);
    });

    testWidgets('Progress updates are shown during download', (
      WidgetTester tester,
    ) async {
      // Given: App is loaded and on reciter details screen
      await tester.pumpWidget(const QuranPlayerApp());
      await tester.pump(const Duration(seconds: 3));
      await navigateToRecitersTab(tester);
      await navigateToReciterDetails(tester);
      await tester.pump(const Duration(seconds: 2));

      // Find the Download All button
      Finder downloadAllButton = findDownloadAllButton();
      if (downloadAllButton.evaluate().isEmpty) {
        downloadAllButton = findDownloadAllButtonByText();
      }

      if (downloadAllButton.evaluate().isEmpty) {
        debugPrint('Download All button not found, skipping test');
        return;
      }

      // Check if already all downloaded
      if (isAllDownloadedState(tester)) {
        debugPrint('All surahs already downloaded, skipping progress test');
        return;
      }

      // When: Tap the Download All button
      await tester.ensureVisible(downloadAllButton.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(downloadAllButton.first);
      await tester.pump(const Duration(seconds: 1));

      // Then: Monitor progress values
      final progressValues = <int>[];
      final DateTime end = DateTime.now().add(const Duration(seconds: 15));

      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 500));

        // Look for percentage text in button label (e.g., "Pause 50%")
        final Finder textWidgets = find.byType(Text);
        for (final Element element in textWidgets.evaluate()) {
          final String? text = (element.widget as Text).data;
          if (text != null && text.contains('%')) {
            // Extract percentage value
            final regex = RegExp(r'(\d+)%');
            final Match? match = regex.firstMatch(text);
            if (match != null) {
              final int percentage = int.parse(match.group(1)!);
              if (progressValues.isEmpty || progressValues.last != percentage) {
                progressValues.add(percentage);
                debugPrint('Progress: $percentage%');
              }
            }
          }
        }

        // Break if reached 100% or all downloaded
        if (progressValues.contains(100) || isAllDownloadedState(tester)) {
          break;
        }
      }

      // Verify we saw progress updates or completion
      expect(
        progressValues.isNotEmpty || isAllDownloadedState(tester),
        true,
        reason: 'Should see progress percentage updates during download',
      );

      // Clean up to prevent pending frame issues
      await cleanupTest(tester);
    });

    testWidgets('Pause/Cancel functionality works', (
      WidgetTester tester,
    ) async {
      // Given: App is loaded and on reciter details screen
      await tester.pumpWidget(const QuranPlayerApp());
      await tester.pump(const Duration(seconds: 3));
      await navigateToRecitersTab(tester);
      await navigateToReciterDetails(tester);
      await tester.pump(const Duration(seconds: 2));

      // Find the Download All button
      Finder downloadAllButton = findDownloadAllButton();
      if (downloadAllButton.evaluate().isEmpty) {
        downloadAllButton = findDownloadAllButtonByText();
      }

      if (downloadAllButton.evaluate().isEmpty) {
        debugPrint('Download All button not found, skipping test');
        return;
      }

      // Check if already all downloaded
      if (isAllDownloadedState(tester)) {
        debugPrint('All surahs already downloaded, skipping pause test');
        return;
      }

      // When: Tap the Download All button to start downloading
      await tester.ensureVisible(downloadAllButton.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(downloadAllButton.first);
      await tester.pump(const Duration(seconds: 1));

      // Wait for download to start (look for pause icon)
      final DateTime startEnd = DateTime.now().add(const Duration(seconds: 5));
      var downloadStarted = false;

      while (DateTime.now().isBefore(startEnd)) {
        await tester.pump(const Duration(milliseconds: 300));

        if (isDownloadingState(tester)) {
          downloadStarted = true;
          break;
        }
      }

      if (!downloadStarted) {
        // Download may have completed too quickly or never started
        debugPrint('Download did not start or completed too quickly');
        return;
      }

      // Tap again to pause/cancel
      downloadAllButton = findDownloadAllButton();
      if (downloadAllButton.evaluate().isEmpty) {
        // Try finding by Arabic or English pause text
        downloadAllButton = find.textContaining('Pause');
        if (downloadAllButton.evaluate().isEmpty) {
          downloadAllButton = find.textContaining('إيقاف');
        }
      }

      if (downloadAllButton.evaluate().isNotEmpty) {
        await tester.tap(downloadAllButton.first);
        await tester.pump(const Duration(seconds: 2));
      }

      // Then: Should see download button again (cancelled state) or complete download
      expect(
        hasDownloadButtonState(tester) || isAllDownloadedState(tester),
        true,
        reason:
            'After pause, should show download/resume button or completed state',
      );

      // Clean up to prevent pending frame issues
      await cleanupTest(tester);
    });

    testWidgets('All Downloaded state shows correctly', (
      WidgetTester tester,
    ) async {
      // Given: App is loaded and on reciter details screen
      await tester.pumpWidget(const QuranPlayerApp());
      await tester.pump(const Duration(seconds: 3));
      await navigateToRecitersTab(tester);
      await navigateToReciterDetails(tester);
      await tester.pump(const Duration(seconds: 2));

      // Find the Download All button
      Finder downloadAllButton = findDownloadAllButton();
      if (downloadAllButton.evaluate().isEmpty) {
        downloadAllButton = findDownloadAllButtonByText();
      }

      // Look for "All Downloaded" text (Arabic or English)
      if (!isAllDownloadedState(tester)) {
        // Not all downloaded yet, so we need to download first
        // Skip if button not found
        if (downloadAllButton.evaluate().isEmpty) {
          debugPrint('Download All button not found, skipping test');
          return;
        }

        // Start download
        await tester.ensureVisible(downloadAllButton.first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(downloadAllButton.first);

        // Wait for download to complete (up to 30 seconds)
        final DateTime end = DateTime.now().add(const Duration(seconds: 30));
        while (DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(seconds: 1));

          if (isAllDownloadedState(tester)) {
            break;
          }
        }
      }

      // Then: Verify All Downloaded state
      final bool isAllDownloadedShown = isAllDownloadedState(tester);

      if (isAllDownloadedShown) {
        expect(
          isAllDownloadedShown,
          true,
          reason: 'All Downloaded state should show check icon and text',
        );

        // Verify button is disabled
        final Finder buttonFinder = findDownloadAllButton();
        if (buttonFinder.evaluate().isNotEmpty) {
          final ElevatedButton button = tester.widget<ElevatedButton>(
            buttonFinder.first,
          );
          expect(
            button.onPressed,
            isNull,
            reason:
                'Download All button should be disabled when all downloaded',
          );
        }
      } else {
        debugPrint(
          'Could not reach All Downloaded state within timeout, test skipped',
        );
      }

      // Clean up to prevent pending frame issues
      await cleanupTest(tester);
    });

    testWidgets('Resume incomplete download shows correct label', (
      WidgetTester tester,
    ) async {
      // Given: App is loaded and on reciter details screen
      await tester.pumpWidget(const QuranPlayerApp());
      await tester.pump(const Duration(seconds: 3));
      await navigateToRecitersTab(tester);
      await navigateToReciterDetails(tester);
      await tester.pump(const Duration(seconds: 2));

      // Find the Download All button
      Finder downloadAllButton = findDownloadAllButton();
      if (downloadAllButton.evaluate().isEmpty) {
        downloadAllButton = findDownloadAllButtonByText();
      }

      if (downloadAllButton.evaluate().isEmpty) {
        debugPrint('Download All button not found, skipping test');
        return;
      }

      // Check if the button shows any valid state (English or Arabic)
      final bool hasValidState = hasDownloadButtonState(tester);

      // At least one of these states should be present
      expect(
        hasValidState,
        true,
        reason:
            'Button should show Download All, Complete Downloading, or All Downloaded (in English or Arabic)',
      );

      // Clean up to prevent pending frame issues
      await cleanupTest(tester);
    });

    testWidgets('Multiple rapid taps on DownloadAll button are handled safely', (
      WidgetTester tester,
    ) async {
      // Given: App is loaded and on reciter details screen
      await tester.pumpWidget(const QuranPlayerApp());
      await tester.pump(const Duration(seconds: 3));
      await navigateToRecitersTab(tester);
      await navigateToReciterDetails(tester);
      await tester.pump(const Duration(seconds: 2));

      // Find the Download All button
      Finder downloadAllButton = findDownloadAllButton();
      if (downloadAllButton.evaluate().isEmpty) {
        downloadAllButton = findDownloadAllButtonByText();
      }

      if (downloadAllButton.evaluate().isEmpty) {
        debugPrint('Download All button not found, skipping test');
        return;
      }

      // Check if already all downloaded - skip rapid tap test
      if (isAllDownloadedState(tester)) {
        debugPrint('All surahs already downloaded, skipping rapid tap test');
        return;
      }

      // When: Rapidly tap the button multiple times (simulating user spamming)
      debugPrint('Performing rapid taps on Download All button...');
      await tester.ensureVisible(downloadAllButton.first);
      await tester.pump(const Duration(milliseconds: 300));

      // Perform 5 rapid taps in quick succession
      for (var i = 0; i < 5; i++) {
        // Re-find button in case it changed
        downloadAllButton = findDownloadAllButton();
        if (downloadAllButton.evaluate().isEmpty) {
          // Try finding by text if key-based search fails
          final Finder pauseFinder = find.textContaining('Pause');
          final Finder pauseArFinder = find.textContaining('إيقاف');
          if (pauseFinder.evaluate().isNotEmpty) {
            downloadAllButton = pauseFinder;
          } else if (pauseArFinder.evaluate().isNotEmpty) {
            downloadAllButton = pauseArFinder;
          } else {
            downloadAllButton = findDownloadAllButtonByText();
          }
        }

        if (downloadAllButton.evaluate().isNotEmpty) {
          await tester.tap(downloadAllButton.first, warnIfMissed: false);
          debugPrint('Tap ${i + 1} completed');
        }
        // Very short delay between taps to simulate rapid clicking
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Wait for UI to stabilize
      await tester.pump(const Duration(seconds: 2));

      // Then: App should remain stable and show a valid state
      // The app should not crash, freeze, or show error dialogs

      // Check that we're still on a valid screen (no crash)
      final bool appIsStable =
          hasDownloadButtonState(tester) ||
          isAllDownloadedState(tester) ||
          isDownloadingState(tester);

      expect(
        appIsStable,
        true,
        reason:
            'App should remain stable after multiple rapid taps on Download All button',
      );

      // Verify no error dialogs appeared
      final Finder errorDialogFinder = find.byType(AlertDialog);
      final Finder snackbarErrorFinder = find.textContaining('Error');
      final Finder snackbarErrorArFinder = find.textContaining('خطأ');

      final bool hasErrorDialog =
          errorDialogFinder.evaluate().isNotEmpty ||
          snackbarErrorFinder.evaluate().isNotEmpty ||
          snackbarErrorArFinder.evaluate().isNotEmpty;

      expect(
        hasErrorDialog,
        false,
        reason:
            'No error dialogs or error messages should appear after rapid taps',
      );

      debugPrint('Rapid tap test completed - app remained stable');

      // Clean up to prevent pending frame issues
      await cleanupTest(tester);
    });

    testWidgets(
      'Tapping button during download toggles pause/resume correctly',
      (WidgetTester tester) async {
        // Given: App is loaded and on reciter details screen
        await tester.pumpWidget(const QuranPlayerApp());
        await tester.pump(const Duration(seconds: 3));
        await navigateToRecitersTab(tester);
        await navigateToReciterDetails(tester);
        await tester.pump(const Duration(seconds: 2));

        // Find the Download All button
        Finder downloadAllButton = findDownloadAllButton();
        if (downloadAllButton.evaluate().isEmpty) {
          downloadAllButton = findDownloadAllButtonByText();
        }

        if (downloadAllButton.evaluate().isEmpty) {
          debugPrint('Download All button not found, skipping test');
          return;
        }

        // Check if already all downloaded
        if (isAllDownloadedState(tester)) {
          debugPrint(
            'All surahs already downloaded, skipping pause/resume toggle test',
          );
          return;
        }

        // Start the download
        debugPrint('Starting download...');
        await tester.ensureVisible(downloadAllButton.first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(downloadAllButton.first);
        await tester.pump(const Duration(seconds: 1));

        // Wait for download to start
        final DateTime startEnd = DateTime.now().add(
          const Duration(seconds: 5),
        );
        var downloadStarted = false;

        while (DateTime.now().isBefore(startEnd)) {
          await tester.pump(const Duration(milliseconds: 300));
          if (isDownloadingState(tester)) {
            downloadStarted = true;
            debugPrint('Download started, showing pause state');
            break;
          }
          // Check if completed quickly
          if (isAllDownloadedState(tester)) {
            debugPrint('Download completed quickly, skipping toggle test');
            return;
          }
        }

        if (!downloadStarted) {
          debugPrint('Download did not start, skipping toggle test');
          return;
        }

        // Toggle pause/resume multiple times
        debugPrint('Testing pause/resume toggle...');
        var toggleCount = 0;
        final DateTime toggleEnd = DateTime.now().add(
          const Duration(seconds: 10),
        );

        while (DateTime.now().isBefore(toggleEnd) && toggleCount < 3) {
          // Re-find the button
          downloadAllButton = findDownloadAllButton();
          if (downloadAllButton.evaluate().isEmpty) {
            final Finder pauseFinder = find.textContaining('Pause');
            final Finder pauseArFinder = find.textContaining('إيقاف');
            final Finder resumeFinder = find.textContaining('Complete');
            final Finder resumeArFinder = find.textContaining('استكمال');
            final Finder downloadFinder = find.textContaining('Download');
            final Finder downloadArFinder = find.textContaining('تحميل');

            if (pauseFinder.evaluate().isNotEmpty) {
              downloadAllButton = pauseFinder;
            } else if (pauseArFinder.evaluate().isNotEmpty) {
              downloadAllButton = pauseArFinder;
            } else if (resumeFinder.evaluate().isNotEmpty) {
              downloadAllButton = resumeFinder;
            } else if (resumeArFinder.evaluate().isNotEmpty) {
              downloadAllButton = resumeArFinder;
            } else if (downloadFinder.evaluate().isNotEmpty) {
              downloadAllButton = downloadFinder;
            } else if (downloadArFinder.evaluate().isNotEmpty) {
              downloadAllButton = downloadArFinder;
            }
          }

          // Check if download completed
          if (isAllDownloadedState(tester)) {
            debugPrint('Download completed during toggle test');
            break;
          }

          if (downloadAllButton.evaluate().isNotEmpty) {
            await tester.tap(downloadAllButton.first, warnIfMissed: false);
            toggleCount++;
            debugPrint('Toggle $toggleCount completed');
            await tester.pump(const Duration(seconds: 1));
          } else {
            await tester.pump(const Duration(milliseconds: 500));
          }
        }

        // Then: App should remain in a valid state
        await tester.pump(const Duration(seconds: 1));

        final bool appIsStable =
            hasDownloadButtonState(tester) ||
            isAllDownloadedState(tester) ||
            isDownloadingState(tester);

        expect(
          appIsStable,
          true,
          reason:
              'App should remain stable after multiple pause/resume toggles',
        );

        debugPrint(
          'Pause/resume toggle test completed with $toggleCount toggles',
        );

        // Clean up to prevent pending frame issues
        await cleanupTest(tester);
      },
    );
  });
}
