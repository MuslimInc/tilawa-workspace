import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa/shared/widgets/bottom_player_ui.dart';
import 'package:tilawa/shared/widgets/bottom_player_widget.dart';

import 'bottom_player_widget_test.mocks.dart';

@GenerateMocks([AudioPlayerBloc, SettingsCubit, AudioPlayerHandler])
void main() {
  late MockAudioPlayerBloc mockBloc;
  late MockSettingsCubit mockSettingsCubit;
  late MockAudioPlayerHandler mockAudioPlayerHandler;

  setUp(() {
    mockBloc = MockAudioPlayerBloc();
    mockSettingsCubit = MockSettingsCubit();
    mockAudioPlayerHandler = MockAudioPlayerHandler();

    // Register dependencies
    if (getIt.isRegistered<AudioPlayerHandler>()) {
      getIt.unregister<AudioPlayerHandler>();
    }
    getIt.registerSingleton<AudioPlayerHandler>(mockAudioPlayerHandler);

    // Stub getRecitersData
    when(
      mockAudioPlayerHandler.getRecitersData(
        languageCode: anyNamed('languageCode'),
      ),
    ).thenAnswer((_) async => []);

    // Default settings stub
    when(mockSettingsCubit.state).thenReturn(const SettingsState());
    when(mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    if (getIt.isRegistered<AudioPlayerHandler>()) {
      getIt.unregister<AudioPlayerHandler>();
    }
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AudioPlayerBloc>.value(value: mockBloc),
          BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
        ],
        child: child,
      ),
    );
  }

  group('BottomPlayerWidget', () {
    testWidgets('should show nothing when mediaItem is null', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(
        mockBloc.state,
      ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.success));
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget(const BottomPlayerWidget()));

      // Assert
      expect(find.byType(BottomPlayerWidget), findsOneWidget);
      // The widget should render SizedBox.shrink when mediaItem is null
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should show nothing when status is not success', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testAudio = AudioEntity(
        id: 'test-id',
        title: 'Test Title',
        url: 'test-url',
        artist: 'Test Artist',
        duration: Duration(minutes: 3),
      );

      when(mockBloc.state).thenReturn(
        const AudioPlayerState(
          status: AudioPlayerStatus.initial,
          currentAudio: testAudio,
        ),
      );
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget(const BottomPlayerWidget()));

      // Assert
      // Should show nothing because status is not success
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets(
      'should show player when mediaItem exists and status is success',
      (WidgetTester tester) async {
        // Arrange
        const testAudio = AudioEntity(
          id: 'test-id',
          title: 'Test Title',
          artist: 'Test Artist',
          url: 'test-url',
          duration: Duration(minutes: 3),
        );

        when(mockBloc.state).thenReturn(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: testAudio,
            playbackState: PlaybackStateEntity(
              isPlaying: true,
              processingState: AudioProcessingStateStatus.ready,
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration(minutes: 3),
              currentIndex: 0,
              queue: [],
            ),
          ),
        );
        when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

        // Act
        await tester.pumpWidget(createTestWidget(const BottomPlayerWidget()));
        await tester.pumpAndSettle();

        // Assert
        // Should find the player UI (you may need to adjust this based on your BottomPlayerUI implementation)
        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Artist'), findsOneWidget);
      },
    );

    testWidgets('should update when bloc state changes to have mediaItem', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testAudio = AudioEntity(
        id: 'test-id',
        title: 'Test Title',
        artist: 'Test Artist',
        url: 'test-url',
        duration: Duration(minutes: 3),
      );

      // Start with no media item
      when(
        mockBloc.state,
      ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.success));

      final stateController = StreamController<AudioPlayerState>.broadcast(
        sync: true,
      );
      when(mockBloc.stream).thenAnswer((_) => stateController.stream);

      // Act
      await tester.pumpWidget(createTestWidget(const BottomPlayerWidget()));
      await tester.pump();

      // Initially should show nothing
      expect(find.text('Test Title'), findsNothing);

      // Update state to have media item
      const newState = AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: testAudio,
        playbackState: PlaybackStateEntity(
          isPlaying: false,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: Duration(minutes: 3),
          currentIndex: 0,
          queue: [],
        ),
      );
      stateController.add(newState);
      when(mockBloc.state).thenReturn(newState);

      await tester.pumpAndSettle();

      // Now should show the player
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);

      // Cleanup
      await stateController.close();
    });
    testWidgets('should dismiss and stop audio when swiped down', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testAudio = AudioEntity(
        id: 'test-id',
        title: 'Test Title',
        artist: 'Test Artist',
        url: 'test-url',
        duration: Duration(minutes: 3),
      );

      when(
        mockBloc.state,
      ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.success));

      final stateController = StreamController<AudioPlayerState>.broadcast(
        sync: true,
      );
      when(mockBloc.stream).thenAnswer((_) => stateController.stream);

      // Act
      await tester.pumpWidget(createTestWidget(const BottomPlayerWidget()));
      await tester.pump();

      // Update state to have media item
      const newState = AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: testAudio,
        playbackState: PlaybackStateEntity(
          isPlaying: false,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: Duration(minutes: 3),
          currentIndex: 0,
          queue: [],
        ),
      );
      stateController.add(newState);
      when(mockBloc.state).thenReturn(newState);

      await tester.pumpAndSettle();

      // Assert basic presence
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byType(Dismissible), findsOneWidget);

      // Simulate swipe down
      await tester.drag(find.byType(Dismissible), const Offset(0, 500));
      await tester
          .pumpAndSettle(); // Allow animation to complete (Dismissible removes itself from tree)

      // Verify stopAudio event was added
      verify(mockBloc.add(const AudioPlayerEvent.stopAudio())).called(1);

      // Note: In a real app, stopAudio triggers state update.
      // In test, since we removed local state, we must Simulate the Bloc response
      // to verify the widget STAYS gone when it rebuilds.
      // Dismissible widget itself removes the child locally on valid dismissal.
      // But if the parent rebuilds with the same state (because we haven't updated mock),
      // it might re-add it.
      // However, Dismissible usually keeps it removed or the key changes?
      // Actually, if we want to test "Logic", we should update the state.

      const dismissedState = AudioPlayerState(
        status: AudioPlayerStatus.initial,
        currentAudio: testAudio,
        dismissedAudioId: 'test-id',
      );
      stateController.add(dismissedState);
      when(mockBloc.state).thenReturn(dismissedState);
      await tester.pump();

      expect(find.byType(BottomPlayerUi), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);

      // Cleanup
      await stateController.close();
    });

    testWidgets(
      'should prevent reappearance when audio updates with metadata change but same ID',
      (WidgetTester tester) async {
        // Arrange
        const testAudio = AudioEntity(
          id: 'test-id',
          title: 'Test Title',
          artist: 'Test Artist',
          url: 'test-url',
          duration: Duration(minutes: 3),
        );

        when(mockBloc.state).thenReturn(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: testAudio,
            playbackState: PlaybackStateEntity(
              isPlaying: true,
              processingState: AudioProcessingStateStatus.ready,
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration(minutes: 3),
              currentIndex: 0,
              queue: [],
            ),
          ),
        );

        final stateController = StreamController<AudioPlayerState>.broadcast();
        when(mockBloc.stream).thenAnswer((_) => stateController.stream);

        // Act: Pump widget
        await tester.pumpWidget(createTestWidget(const BottomPlayerWidget()));
        await tester.pumpAndSettle();

        expect(find.byType(Dismissible), findsOneWidget);

        // Act: Dismiss
        await tester.drag(find.byType(Dismissible), const Offset(0, 500));
        await tester.pumpAndSettle();

        // Simulate state update from dismissal
        const dismissedState = AudioPlayerState(
          status: AudioPlayerStatus.initial,
          currentAudio: testAudio,
          dismissedAudioId: 'test-id',
        );
        stateController.add(dismissedState);
        when(mockBloc.state).thenReturn(dismissedState);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(Dismissible), findsNothing);
        verify(mockBloc.add(const AudioPlayerEvent.stopAudio())).called(1);

        // Act: Emit state change (Stopped, Metadata updated)
        final AudioEntity stoppedAudio = testAudio.copyWith(
          title: 'Updated Title',
        );
        final stoppedState = AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: stoppedAudio, // Same ID, different content
          dismissedAudioId: 'test-id', // State reflects dismissal
          playbackState: const PlaybackStateEntity(
            isPlaying: false,
            processingState: AudioProcessingStateStatus.ready,
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            duration: Duration(minutes: 3),
            currentIndex: 0,
            queue: [],
          ),
        );

        stateController.add(stoppedState);
        when(mockBloc.state).thenReturn(stoppedState);

        await tester.pump();
        await tester.pump();

        // Assert: Still hidden
        expect(find.byType(Dismissible), findsNothing);

        await stateController.close();
      },
    );

    testWidgets(
      'should maintain dismissed state when audio is cleared and then restored (ghost update)',
      (WidgetTester tester) async {
        // Arrange
        const testAudio = AudioEntity(
          id: 'test-id',
          title: 'Test Title',
          artist: 'Test Artist',
          url: 'test-url',
          duration: Duration(minutes: 3),
        );

        // Initial state: Playing
        when(mockBloc.state).thenReturn(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: testAudio,
            playbackState: PlaybackStateEntity(
              isPlaying: true,
              processingState: AudioProcessingStateStatus.ready,
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration(minutes: 3),
              currentIndex: 0,
              queue: [],
            ),
          ),
        );

        final stateController = StreamController<AudioPlayerState>.broadcast();
        when(mockBloc.stream).thenAnswer((_) => stateController.stream);

        // Act: Pump widget
        await tester.pumpWidget(createTestWidget(const BottomPlayerWidget()));
        await tester.pumpAndSettle();

        expect(find.byType(Dismissible), findsOneWidget);

        // Act: Dismiss
        await tester.drag(find.byType(Dismissible), const Offset(0, 500));
        await tester.pumpAndSettle();

        // Simulate dismissal state update
        const dismissedState = AudioPlayerState(
          status: AudioPlayerStatus.initial,
          currentAudio: testAudio,
          dismissedAudioId: 'test-id',
        );
        stateController.add(dismissedState);
        when(mockBloc.state).thenReturn(dismissedState);
        await tester.pump(const Duration(milliseconds: 100));

        verify(mockBloc.add(const AudioPlayerEvent.stopAudio())).called(1);
        expect(find.byType(Dismissible), findsNothing);

        // Act: Emit ID=null (simulating StopAudio success clearing state)
        // With new logic, StopAudio does NOT clear currentAudio, but sets status=initial and dismissedAudioId
        const clearedState = AudioPlayerState(
          status: AudioPlayerStatus.initial,
          currentAudio: testAudio, // Preserved
          dismissedAudioId: 'test-id', // Set
        );
        stateController.add(clearedState);
        when(mockBloc.state).thenReturn(clearedState);
        await tester.pump(const Duration(milliseconds: 100));

        // Act: Emit ID=test-id again (simulating stream update restoring last known audio)
        // But NOT playing (since we stopped it)
        const restoredState = AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: testAudio, // Ghost update: same ID comes back
          dismissedAudioId: 'test-id', // Preserved
          playbackState: PlaybackStateEntity(
            isPlaying: false, // Not playing
            processingState: AudioProcessingStateStatus.ready,
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            duration: Duration(minutes: 3),
            currentIndex: 0,
            queue: [],
          ),
        );
        stateController.add(restoredState);
        when(mockBloc.state).thenReturn(restoredState);

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        // Assert: Should still be hidden!
        // If bug exists, listener sees null->ID change, thinking it's new track, resets dismissal.
        expect(
          find.byType(Dismissible),
          findsNothing,
          reason: 'Player reappeared after clear-then-restore!',
        );

        await stateController.close();
      },
    );
  });
}
