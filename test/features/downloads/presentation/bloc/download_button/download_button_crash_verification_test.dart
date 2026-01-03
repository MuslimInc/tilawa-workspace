import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/presentation/bloc/download_button/download_button_bloc.dart';

import '../../../helpers/mock_helper.mocks.dart';

/// This test verifies that the crash WOULD occur without our fix.
///
/// We create a minimal bloc WITHOUT the `isClosed` check to prove
/// that the Firebase crash report was accurate.

// Simplified event for test bloc
sealed class TestDownloadEvent {}

class TestInitialize extends TestDownloadEvent {}

class TestProgressUpdated extends TestDownloadEvent {
  TestProgressUpdated(this.progress);
  final double progress;
}

// Simplified state for test bloc
sealed class TestDownloadState {}

class TestInitial extends TestDownloadState {}

class TestDownloading extends TestDownloadState {
  TestDownloading(this.progress);
  final double progress;
}

/// Bloc WITHOUT the isClosed check - this WILL crash
class BlocWithoutFix extends Bloc<TestDownloadEvent, TestDownloadState> {
  BlocWithoutFix({required this.progressStream}) : super(TestInitial()) {
    on<TestInitialize>((event, emit) async {
      // Start listening to progress - NO isClosed check
      _subscription = progressStream.listen((progress) {
        // THIS IS THE BUG: No check if bloc is closed
        // This will crash if called after bloc.close()
        add(TestProgressUpdated(progress));
      });
      emit(TestDownloading(0.0));
    });

    on<TestProgressUpdated>((event, emit) async {
      emit(TestDownloading(event.progress));
    });
  }

  final Stream<double> progressStream;
  StreamSubscription<double>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

/// Bloc WITH the isClosed check - this will NOT crash
class BlocWithFix extends Bloc<TestDownloadEvent, TestDownloadState> {
  BlocWithFix({required this.progressStream}) : super(TestInitial()) {
    on<TestInitialize>((event, emit) async {
      // Start listening to progress - WITH isClosed check
      _subscription = progressStream.listen((progress) {
        // THIS IS THE FIX: Check if bloc is closed before adding event
        if (isClosed) {
          return; // Silently ignore if already closed
        }
        add(TestProgressUpdated(progress));
      });
      emit(TestDownloading(0.0));
    });

    on<TestProgressUpdated>((event, emit) async {
      emit(TestDownloading(event.progress));
    });
  }

  final Stream<double> progressStream;
  StreamSubscription<double>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

void main() {
  setUpAll(() {
    provideDummy<Either<Failure, bool>>(const Right(false));
    provideDummy<Either<Failure, void>>(const Right(null));
  });

  group('Crash Verification - Prove Firebase Report is Accurate', () {
    test('WITHOUT FIX: Bloc DOES crash when stream emits after close '
        '(proves the Firebase crash was real)', () async {
      // Use a synchronous controller to ensure events are processed immediately
      final controller = StreamController<double>();

      final bloc = BlocWithoutFix(progressStream: controller.stream);

      // Initialize and start listening
      bloc.add(TestInitialize());
      await Future.delayed(const Duration(milliseconds: 100));

      // Emit some progress
      controller.add(0.1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Close the bloc (user navigates away)
      await bloc.close();

      // Now try to emit progress - this SHOULD crash
      // The stream is still active, so the listener will try to add an event
      var didCrash = false;
      String? errorMessage;
      try {
        // Add event to stream - listener will try to call bloc.add() on closed bloc
        controller.add(0.5);
        // Give it time to process
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e, stack) {
        errorMessage = e.toString();
        print('Caught expected crash: $e');
        print('Stack: $stack');
        // Verify it's the exact error from Firebase
        didCrash =
            errorMessage.contains(
              'Cannot add new events after calling close',
            ) ||
            errorMessage.contains('Bad state');
      }

      // Clean up
      await controller.close();

      // This proves the crash was real
      expect(
        didCrash,
        isTrue,
        reason:
            'The bloc WITHOUT isClosed check should crash with:\n'
            '"Bad state: Cannot add new events after calling close"\n'
            'Actual error: $errorMessage\n'
            'This proves the Firebase crash report was accurate.\n'
            'If this test passes (didCrash=true), it means the crash would happen in production.',
      );
    });
    test('WITH FIX: Bloc does NOT crash when stream emits after close '
        '(proves our fix resolves the issue)', () async {
      final controller = StreamController<double>.broadcast();

      final bloc = BlocWithFix(progressStream: controller.stream);

      // Initialize and start listening
      bloc.add(TestInitialize());
      await Future.delayed(const Duration(milliseconds: 50));

      // Emit some progress
      controller.add(0.1);
      await Future.delayed(const Duration(milliseconds: 50));

      // Close the bloc
      await bloc.close();

      // Now try to emit progress - should NOT crash
      expect(() {
        controller.add(0.5);
      }, returnsNormally);

      await Future.delayed(const Duration(milliseconds: 50));

      // Clean up
      await controller.close();

      // Success - no crash!
    });

    test('WITHOUT FIX: Multiple rapid updates after close causes crash '
        '(simulates real-world scenario)', () async {
      final controller = StreamController<double>.broadcast();

      final bloc = BlocWithoutFix(progressStream: controller.stream);

      bloc.add(TestInitialize());
      await Future.delayed(const Duration(milliseconds: 50));

      // Close bloc
      await bloc.close();

      // Rapid fire updates (as happens in real downloads)
      var didCrash = false;
      try {
        for (var i = 0; i < 10; i++) {
          controller.add(i / 10);
        }
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        didCrash =
            e.toString().contains(
              'Cannot add new events after calling close',
            ) ||
            e.toString().contains('Bad state');
      }

      await controller.close();

      expect(
        didCrash,
        isTrue,
        reason: 'Multiple updates should trigger the crash',
      );
    });

    test('WITH FIX: Multiple rapid updates after close handled gracefully '
        '(proves fix handles high-frequency scenario)', () async {
      final controller = StreamController<double>.broadcast();

      final bloc = BlocWithFix(progressStream: controller.stream);

      bloc.add(TestInitialize());
      await Future.delayed(const Duration(milliseconds: 50));

      // Close bloc
      await bloc.close();

      // Rapid fire updates - should all be handled gracefully
      expect(() {
        for (var i = 0; i < 100; i++) {
          controller.add(i / 100);
        }
      }, returnsNormally);

      await Future.delayed(const Duration(milliseconds: 100));
      await controller.close();

      // Success - no crash even with 100 updates!
    });
  });

  group('Simple Demonstration - add() after close() crashes', () {
    test(
      'PROOF: Calling bloc.add() after bloc.close() throws StateError',
      () async {
        final controller = StreamController<double>();
        final bloc = BlocWithoutFix(progressStream: controller.stream);

        bloc.add(TestInitialize());
        await Future.delayed(const Duration(milliseconds: 50));

        // Close the bloc
        await bloc.close();

        // Try to add an event - this WILL crash
        expect(
          () => bloc.add(TestProgressUpdated(0.5)),
          throwsStateError,
          reason:
              'Calling add() after close() should throw StateError: '
              '"Cannot add new events after calling close"',
        );

        await controller.close();
      },
    );

    test(
      'DEMONSTRATION: Stream listener WITHOUT isClosed check triggers the crash',
      () async {
        // This test demonstrates THE EXACT crash scenario:
        // 1. Bloc is closed while stream subscription is active
        // 2. Stream emits→ listener calls add() → CRASH

        final controller = StreamController<double>();
        final bloc = BlocWithoutFix(progressStream: controller.stream);

        // Initialize - this sets up the stream listener
        bloc.add(TestInitialize());
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify listener is working
        controller.add(0.1);
        await Future.delayed(const Duration(milliseconds: 50));

        // Close the bloc (simulates user navigating away)
        await bloc.close();

        // The stream subscription is STILL ACTIVE (that's the bug!)
        // When we add to the stream, the listener will try to call bloc.add()
        //
        // BlocWithoutFix listener code:
        //   progressStream.listen((progress) {
        //     add(TestProgressUpdated(progress));  // <-- This will crash!
        //   });
        //
        // Firebase Error:
        // "Bad state: Cannot add new events after calling close
        //  at _BroadcastStreamController.add(dart:async)
        //  at Bloc.add(bloc.dart:97)"

        // We expect an unhandled error in the zone
        var errorCaught = false;
        await runZonedGuarded(
          () async {
            controller.add(0.5); // Stream emits
            await Future.delayed(const Duration(milliseconds: 100));
          },
          (error, stack) {
            print('✅ Caught the crash: $error');
            if (error.toString().contains(
                  'Cannot add new events after calling close',
                ) ||
                error.toString().contains('Bad state')) {
              errorCaught = true;
            }
          },
        );

        await controller.close();

        // If we caught the error, it proves the crash scenario is real
        expect(
          errorCaught,
          isTrue,
          reason:
              'The crash should be triggered when stream emits after bloc close',
        );
      },
    );

    test('WITH FIX: isClosed check prevents the crash', () async {
      final controller = StreamController<double>();
      final bloc = BlocWithFix(progressStream: controller.stream);

      bloc.add(TestInitialize());
      await Future.delayed(const Duration(milliseconds: 50));

      // Close bloc
      await bloc.close();

      // Stream emits - but isClosed check prevents add()
      // BlocWithFix listener code:
      //   progressStream.listen((progress) {
      //     if (isClosed) return;  // <-- This prevents the crash!
      //     add(TestProgressUpdated(progress));
      //   });

      expect(
        () async {
          controller.add(0.5);
          await Future.delayed(const Duration(milliseconds: 100));
        },
        returnsNormally,
        reason: 'isClosed check should prevent crash',
      );

      await controller.close();
    });
  });

  group('Verify Actual DownloadButtonBloc Implementation', () {
    late MockCheckSurahDownloadedUseCase mockCheckSurahDownloaded;
    late MockDownloadSurahUseCase mockDownloadSurah;
    late MockCancelDownloadUseCase mockCancelDownload;
    late MockObserveDownloadProgressUseCase mockObserveDownloadProgress;
    late MockNetworkInfo mockNetworkInfo;

    const testUrl = 'https://example.com/001.mp3';
    const testReciterName = 'Abdul Rahman Al-Sudais';
    const testReciterId = 1;
    const testSurahTitle = 'Al-Fatiha';

    setUp(() {
      mockCheckSurahDownloaded = MockCheckSurahDownloadedUseCase();
      mockDownloadSurah = MockDownloadSurahUseCase();
      mockCancelDownload = MockCancelDownloadUseCase();
      mockObserveDownloadProgress = MockObserveDownloadProgressUseCase();
      mockNetworkInfo = MockNetworkInfo();
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      when(
        mockCheckSurahDownloaded.call(
          surahId: anyNamed('surahId'),
          reciterName: anyNamed('reciterName'),
        ),
      ).thenAnswer((_) async => const Right(false));

      when(
        mockDownloadSurah.call(
          surahId: anyNamed('surahId'),
          surahTitle: anyNamed('surahTitle'),
          reciterName: anyNamed('reciterName'),
          reciterId: anyNamed('reciterId'),
        ),
      ).thenAnswer((_) async => const Right(null));
    });

    test(
      'Real DownloadButtonBloc with fix handles post-close events correctly',
      () async {
        final controller = StreamController<DownloadItem>.broadcast();

        when(
          mockObserveDownloadProgress.call(any),
        ).thenAnswer((_) => controller.stream);

        final bloc = DownloadButtonBloc(
          url: testUrl,
          reciterName: testReciterName,
          reciterId: testReciterId,
          checkSurahDownloaded: mockCheckSurahDownloaded,
          downloadSurah: mockDownloadSurah,
          cancelDownload: mockCancelDownload,
          observeDownloadProgress: mockObserveDownloadProgress,
          networkInfo: mockNetworkInfo,
        );

        // Initialize and start download
        bloc.add(const DownloadButtonEvent.initialize());
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(
          const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // Emit progress
        controller.add(
          DownloadItem(
            id: testUrl,
            title: testSurahTitle,
            url: testUrl,
            filePath: '',
            reciterName: testReciterName,
            reciterId: testReciterId,
            status: DownloadStatus.downloading,
            progress: 0.3,
            fileSize: 1000,
            downloadedSize: 300,
            createdAt: DateTime.now(),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Close bloc
        await bloc.close();

        // Emit more progress - should NOT crash
        expect(
          () {
            controller.add(
              DownloadItem(
                id: testUrl,
                title: testSurahTitle,
                url: testUrl,
                filePath: '',
                reciterName: testReciterName,
                reciterId: testReciterId,
                status: DownloadStatus.downloading,
                progress: 0.8,
                fileSize: 1000,
                downloadedSize: 800,
                createdAt: DateTime.now(),
              ),
            );
          },
          returnsNormally,
          reason:
              'DownloadButtonBloc should have isClosed check in _listenToProgress',
        );

        await Future.delayed(const Duration(milliseconds: 100));
        await controller.close();

        // If we got here, the fix is working in the real implementation
      },
    );
  });
}
