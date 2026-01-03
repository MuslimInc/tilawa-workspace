import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/shared/widgets/bottom_player_ui.dart';
import 'package:tilawa/shared/widgets/bottom_player_widget.dart';

import 'bottom_player_widget_test.mocks.dart';

@GenerateMocks([AudioPlayerBloc, SettingsCubit])
void main() {
  late MockAudioPlayerBloc mockBloc;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    mockBloc = MockAudioPlayerBloc();
    mockSettingsCubit = MockSettingsCubit();

    // Default settings stub
    when(mockSettingsCubit.state).thenReturn(const SettingsState());
    when(mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());
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

      final stateController = StreamController<AudioPlayerState>.broadcast();
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

      final stateController = StreamController<AudioPlayerState>.broadcast();
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
      await tester.pumpAndSettle(); // Allow animation to complete

      // Verify stopAudio event was added
      verify(mockBloc.add(const AudioPlayerEvent.stopAudio())).called(1);

      // Verify widget is practically gone or logically handling dismissal
      // Since we simulate dismissal via state change in the widget,
      // and stopAudio triggers a state change in the bloc which eventually removes the mediaItem or stops playing.
      // But in this test environment, we control the bloc state.
      // The widget internal state `_manuallyDismissed` should be true, so it should rebuild as SizedBox.shrink
      await tester
          .pump(); // trigger rebuild based on setState inside onDismissed
      expect(find.byType(BottomPlayerUi), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);

      // Cleanup
      await stateController.close();
    });
  });
}
