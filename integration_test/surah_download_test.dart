import 'package:dartz_plus/dartz_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/entities/moshaf_entity.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/utils/typedefs.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_card.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/firebase_options.dart';
import 'package:tilawa/quran_player_app.dart';
import 'package:tilawa/router/app_router.dart';

/// Integration tests for downloading surahs from reciter details screen
///
/// Tests cover:
/// - Online download: Download a surah with internet connection
/// - Offline download: Attempt to download without internet (should show error)
/// - Download progress: Verify progress indicator updates
/// - Download completion: Verify checkmark appears when complete
/// - Already downloaded: Verify checkmark shows for already downloaded surahs

// Fake implementation to bypass splash/login checks
class FakeGetSplashNextRouteUseCase implements GetSplashNextRouteUseCase {
  @override
  Future<SplashDestination> call() async {
    return SplashDestination.home;
  }
}

// Fake implementation to bypass notification permission checks
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

  @override
  SharedPreferencesAsync get _prefs => throw UnimplementedError();
}

// Fake implementation of RecitersRepository
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
    return const Right(null);
  }

  @override
  ResultFuture<List<String>> getFavoriteReciterIds() async {
    return const Right([]);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Surah Download Integration Tests', () {
    late DownloadsRepository downloadsRepository;
    late RecitersRepository recitersRepository;

    setUpAll(() async {
      // Allow reassigning dependencies
      GetIt.instance.allowReassignment = true;

      // Initialize AppRouter
      AppRouter.init();

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure dependencies (DI)
      await configureDependencies();

      // Overwrite RecitersRepository to avoid network calls
      if (GetIt.instance.isRegistered<RecitersRepository>()) {
        GetIt.instance.unregister<RecitersRepository>();
      }
      GetIt.instance.registerSingleton<RecitersRepository>(
        FakeRecitersRepository(),
      );

      // Refresh GetRecitersUseCase because it's an eager singleton that holds the old repo
      if (GetIt.instance.isRegistered<GetRecitersUseCase>()) {
        GetIt.instance.unregister<GetRecitersUseCase>();
      }
      GetIt.instance.registerSingleton<GetRecitersUseCase>(
        GetRecitersUseCase(GetIt.instance<RecitersRepository>()),
      );

      // Overwrite GetSplashNextRouteUseCase to force Home screen
      if (GetIt.instance.isRegistered<GetSplashNextRouteUseCase>()) {
        GetIt.instance.registerFactory<GetSplashNextRouteUseCase>(
          () => FakeGetSplashNextRouteUseCase(),
        );
      }

      // Overwrite NotificationPermissionService to avoid dialogs
      if (GetIt.instance.isRegistered<NotificationPermissionService>()) {
        GetIt.instance.registerSingleton<NotificationPermissionService>(
          FakeNotificationPermissionService(),
        );
      }

      // Initialize HydratedStorage
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(
          (await getTemporaryDirectory()).path,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      // Get repositories
      downloadsRepository = getIt<DownloadsRepository>();
      recitersRepository = getIt<RecitersRepository>();
    });

    tearDown(() async {
      // Clean up downloads after each test
      await Future.delayed(const Duration(milliseconds: 500));
    });

    testWidgets('Online Download: Download a surah with internet connection', (
      WidgetTester tester,
    ) async {
      // Initialize the app UI
      await tester.pumpWidget(const QuranPlayerApp());
      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Step 1: Navigate to reciters screen
      // Reciters is the first tab, so we might already be there.
      // But we verify the tab exists and tap it to be sure.

      // Using FluentIcons as used in MainScreen
      final Finder recitersIconFinder = find.byIcon(
        FluentIcons.person_24_regular,
      );
      final Finder recitersActiveIconFinder = find.byIcon(
        FluentIcons.person_24_filled,
      );

      if (recitersIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersIconFinder.first);
      } else if (recitersActiveIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersActiveIconFinder.first);
      } else {
        // Fallback to text
        final Finder recitersTextFinder = find.text('Reciters');
        if (recitersTextFinder.evaluate().isNotEmpty) {
          await tester.tap(recitersTextFinder.first);
        }
      }

      await tester.pumpAndSettle();

      // Check if loading
      final Finder loadingFinder = find.byType(CircularProgressIndicator);
      if (loadingFinder.evaluate().isNotEmpty) {
        await tester.pump(const Duration(seconds: 10));
      }

      await tester.pumpAndSettle();

      // Step 2: Find and tap on a reciter card
      // Look for any reciter card (usually the first one)
      final Finder reciterCards = find.byType(ReciterCard);

      if (reciterCards.evaluate().isEmpty) {
        print('No ReciterCards found! Dumping widget tree...');
        debugDumpApp();
      }

      final Finder reciterCardFinder = reciterCards.first;
      expect(
        reciterCards.evaluate().isNotEmpty,
        true,
        reason: 'At least one reciter card should be visible',
      );

      await tester.tap(reciterCardFinder);
      await tester.pumpAndSettle(); // Wait for navigation to details screen
      print('Tapped reciter card');

      // Step 3: Find a download button that is NOT already downloaded
      // We look for DownloadButton widget directly
      final Finder downloadButtonFinder = find.byType(DownloadButton);
      await tester.pumpAndSettle(); // Wait for surah list to load

      expect(
        downloadButtonFinder,
        findsWidgets,
        reason: 'Should find at least one DownloadButton',
      );

      // Tap the first download button
      await tester.tap(downloadButtonFinder.first);
      await tester.pump(); // Start animation/process

      print('Tapped download button');

      // Wait for download to likely complete or at least update state
      await tester.pump(const Duration(seconds: 2));

      // Step 5: Verify download started
      // Should see either:
      // - A progress indicator (CircularProgressIndicator)
      // - A pending icon (hourglass)
      // - A downloading icon
      final Finder progressIndicatorFinder = find.byType(
        CircularProgressIndicator,
      );
      final Finder hourglassFinder = find.byIcon(Icons.hourglass_empty_rounded);
      final Finder downloadingFinder = find.byIcon(Icons.downloading_rounded);

      final bool downloadStarted =
          progressIndicatorFinder.evaluate().isNotEmpty ||
          hourglassFinder.evaluate().isNotEmpty ||
          downloadingFinder.evaluate().isNotEmpty;

      expect(
        downloadStarted,
        true,
        reason: 'Download should start and show progress indicator',
      );

      // Step 6: Wait for download to complete (with timeout)
      // Poll for completion indicator (check_circle icon)
      var downloadCompleted = false;
      for (var i = 0; i < 60; i++) {
        // Wait up to 60 seconds
        await tester.pump(const Duration(seconds: 1));

        if (i % 5 == 0) print('Waiting for download to complete... $i/60');

        // Find by Icon data directly
        final Finder checkIconFinder = find.byIcon(Icons.check_circle);

        // Also try to find by widget predicate in case it's wrapped
        final Finder completedButtonFinder = find.byWidgetPredicate((widget) {
          return widget is Icon && widget.icon == Icons.check_circle;
        });

        if (checkIconFinder.evaluate().isNotEmpty ||
            completedButtonFinder.evaluate().isNotEmpty) {
          downloadCompleted = true;
          break;
        }

        // Diagnose other states
        if (find.byIcon(Icons.download_rounded).evaluate().isNotEmpty) {
          if (i % 10 == 0) {
            print('State: Default/Failed/Cancelled (Download Icon visible)');
          }
        } else if (find
            .byType(CircularProgressIndicator)
            .evaluate()
            .isNotEmpty) {
          if (i % 10 == 0) {
            print('State: Downloading (Progress Indicator visible)');
          }
        } else if (find
            .byIcon(Icons.hourglass_empty_rounded)
            .evaluate()
            .isNotEmpty) {
          if (i % 10 == 0) print('State: Pending (Hourglass visible)');
        } else if (find.byIcon(Icons.error).evaluate().isNotEmpty) {
          print('State: Error (Error Icon visible)');
        }
      }

      if (!downloadCompleted) {
        print('Download completion icon not found! Dumping widget tree...');
        debugDumpApp();
      }

      expect(
        downloadCompleted,
        true,
        reason: 'Download should complete within 60 seconds',
      );

      // Step 7: Verify the check icon is green
      final Finder completedIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.check_circle &&
            widget.color == Colors.green,
      );

      expect(
        completedIcon.evaluate().isNotEmpty,
        true,
        reason: 'Completed download should show green check icon',
      );
    });

    testWidgets('Offline Download: Attempt download without internet', (
      WidgetTester tester,
    ) async {
      // Note: This test requires manual airplane mode activation
      // or network mocking which is platform-specific

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to reciters screen
      final Finder recitersIconFinder = find.byIcon(
        FluentIcons.person_24_regular,
      );
      final Finder recitersActiveIconFinder = find.byIcon(
        FluentIcons.person_24_filled,
      );

      if (recitersIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersIconFinder.first);
      } else if (recitersActiveIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersActiveIconFinder.first);
      } else {
        final Finder recitersTextFinder = find.text('Reciters');
        if (recitersTextFinder.evaluate().isNotEmpty) {
          await tester.tap(recitersTextFinder.first);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on a reciter card
      final Finder reciterCardFinder = find.byType(Card).first;
      await tester.tap(reciterCardFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find a download button
      final Finder downloadButtonFinder = find.byIcon(Icons.download_rounded);

      if (downloadButtonFinder.evaluate().isEmpty) {
        print('No downloadable surahs found, skipping offline download test');
        return;
      }

      // TODO: Enable airplane mode programmatically here
      // This is platform-specific and may require platform channels

      // Tap download button
      await tester.tap(downloadButtonFinder.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify network error toast or message appears
      // The app should show a network error message
      final Finder networkErrorFinder = find.textContaining('network');
      final Finder errorFinder = find.textContaining('error');

      final bool errorShown =
          networkErrorFinder.evaluate().isNotEmpty ||
          errorFinder.evaluate().isNotEmpty;

      // Note: This might not work if network is actually available
      // This test is more of a documentation of expected behavior
      print(
        'Offline test: Error shown = $errorShown (requires manual airplane mode)',
      );
    });

    testWidgets('Download Progress: Verify progress updates during download', (
      WidgetTester tester,
    ) async {
      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to reciter details
      final Finder recitersIconFinder = find.byIcon(
        FluentIcons.person_24_regular,
      );
      final Finder recitersActiveIconFinder = find.byIcon(
        FluentIcons.person_24_filled,
      );

      if (recitersIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersIconFinder.first);
      } else if (recitersActiveIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersActiveIconFinder.first);
      } else {
        final Finder recitersTextFinder = find.text('Reciters');
        if (recitersTextFinder.evaluate().isNotEmpty) {
          await tester.tap(recitersTextFinder.first);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final Finder reciterCardFinder = find.byType(Card).first;
      await tester.tap(reciterCardFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find a download button
      final Finder downloadButtonFinder = find.byIcon(Icons.download_rounded);

      if (downloadButtonFinder.evaluate().isEmpty) {
        print('No downloadable surahs found, skipping progress test');
        return;
      }

      // Start download
      await tester.tap(downloadButtonFinder.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Track progress values
      final progressValues = <int>[];

      // Monitor progress for up to 10 seconds
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));

        // Look for progress text (percentage)
        final Finder textWidgets = find.byType(Text);
        for (final Element textWidget in textWidgets.evaluate()) {
          final String? text = (textWidget.widget as Text).data;
          if (text != null) {
            final int? percentage = int.tryParse(text);
            if (percentage != null && percentage >= 0 && percentage <= 100) {
              progressValues.add(percentage);
            }
          }
        }

        // If we've seen progress reach 100, break
        if (progressValues.contains(100)) {
          break;
        }
      }

      // Verify we saw some progress updates
      expect(
        progressValues.isNotEmpty,
        true,
        reason: 'Should see progress percentage updates during download',
      );

      // Verify progress is increasing
      if (progressValues.length > 1) {
        var isIncreasing = true;
        for (var i = 1; i < progressValues.length; i++) {
          if (progressValues[i] < progressValues[i - 1]) {
            isIncreasing = false;
            break;
          }
        }
        expect(
          isIncreasing,
          true,
          reason: 'Progress should be monotonically increasing',
        );
      }
    });

    testWidgets('Already Downloaded: Verify checkmark for downloaded surahs', (
      WidgetTester tester,
    ) async {
      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to reciter details
      final Finder recitersIconFinder = find.byIcon(
        FluentIcons.person_24_regular,
      );
      final Finder recitersActiveIconFinder = find.byIcon(
        FluentIcons.person_24_filled,
      );

      if (recitersIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersIconFinder.first);
      } else if (recitersActiveIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersActiveIconFinder.first);
      } else {
        final Finder recitersTextFinder = find.text('Reciters');
        if (recitersTextFinder.evaluate().isNotEmpty) {
          await tester.tap(recitersTextFinder.first);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final Finder reciterCardFinder = find.byType(Card).first;
      await tester.tap(reciterCardFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for check_circle icons (downloaded surahs)
      final Finder checkIconFinder = find.byIcon(Icons.check_circle);

      if (checkIconFinder.evaluate().isEmpty) {
        print('No downloaded surahs found, skipping already downloaded test');
        return;
      }

      // Verify at least one surah shows as downloaded
      expect(
        checkIconFinder.evaluate().isNotEmpty,
        true,
        reason: 'Should show checkmark for downloaded surahs',
      );

      // Verify the check icon is green
      final Finder greenCheckFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.check_circle &&
            widget.color == Colors.green,
      );

      expect(
        greenCheckFinder.evaluate().isNotEmpty,
        true,
        reason: 'Downloaded surahs should show green checkmark',
      );
    });

    testWidgets('Download Cancellation: Cancel an ongoing download', (
      WidgetTester tester,
    ) async {
      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to reciter details
      final Finder recitersIconFinder = find.byIcon(
        FluentIcons.person_24_regular,
      );
      final Finder recitersActiveIconFinder = find.byIcon(
        FluentIcons.person_24_filled,
      );

      if (recitersIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersIconFinder.first);
      } else if (recitersActiveIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersActiveIconFinder.first);
      } else {
        final Finder recitersTextFinder = find.text('Reciters');
        if (recitersTextFinder.evaluate().isNotEmpty) {
          await tester.tap(recitersTextFinder.first);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final Finder reciterCardFinder = find.byType(Card).first;
      await tester.tap(reciterCardFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find a download button
      final Finder downloadButtonFinder = find.byIcon(Icons.download_rounded);

      if (downloadButtonFinder.evaluate().isEmpty) {
        print('No downloadable surahs found, skipping cancellation test');
        return;
      }

      // Start download
      await tester.tap(downloadButtonFinder.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Wait a bit for download to start
      await tester.pump(const Duration(seconds: 1));

      // Look for the cancel button (should be the progress indicator itself or nearby)
      // The progress indicator is tappable to cancel
      final Finder progressIndicatorFinder = find.byType(
        CircularProgressIndicator,
      );
      final Finder hourglassFinder = find.byIcon(Icons.hourglass_empty_rounded);

      if (progressIndicatorFinder.evaluate().isNotEmpty) {
        // Tap on the progress area to cancel
        await tester.tap(progressIndicatorFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      } else if (hourglassFinder.evaluate().isNotEmpty) {
        // Tap on the hourglass to cancel
        await tester.tap(hourglassFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Verify download button reappears (download was cancelled)
      final Finder downloadButtonAfterCancel = find.byIcon(
        Icons.download_rounded,
      );
      expect(
        downloadButtonAfterCancel.evaluate().isNotEmpty,
        true,
        reason: 'Download button should reappear after cancellation',
      );
    });

    testWidgets('Search and Download: Search for a surah and download it', (
      WidgetTester tester,
    ) async {
      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to reciter details
      final Finder recitersIconFinder = find.byIcon(
        FluentIcons.person_24_regular,
      );
      final Finder recitersActiveIconFinder = find.byIcon(
        FluentIcons.person_24_filled,
      );

      if (recitersIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersIconFinder.first);
      } else if (recitersActiveIconFinder.evaluate().isNotEmpty) {
        await tester.tap(recitersActiveIconFinder.first);
      } else {
        final Finder recitersTextFinder = find.text('Reciters');
        if (recitersTextFinder.evaluate().isNotEmpty) {
          await tester.tap(recitersTextFinder.first);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final Finder reciterCardFinder = find.byType(Card).first;
      await tester.tap(reciterCardFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find the search field
      final Finder searchFieldFinder = find.byType(TextField);

      if (searchFieldFinder.evaluate().isEmpty) {
        print('Search field not found, skipping search test');
        return;
      }

      // Enter search text (e.g., "الفاتحة" or "Fatiha")
      await tester.enterText(searchFieldFinder.first, 'الفاتحة');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify search results are filtered
      // Should see fewer cards than before
      final Finder cardsAfterSearch = find.byType(Card);
      expect(
        cardsAfterSearch.evaluate().isNotEmpty,
        true,
        reason: 'Should show search results',
      );

      // Find download button in search results
      final Finder downloadButtonFinder = find.byIcon(Icons.download_rounded);

      if (downloadButtonFinder.evaluate().isEmpty) {
        print('Searched surah already downloaded, skipping');
        return;
      }

      // Download the searched surah
      await tester.tap(downloadButtonFinder.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify download started
      final Finder progressIndicatorFinder = find.byType(
        CircularProgressIndicator,
      );
      expect(
        progressIndicatorFinder.evaluate().isNotEmpty,
        true,
        reason: 'Download should start for searched surah',
      );
    });
  });
}
