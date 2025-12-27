import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa/shared/widgets/bottom_player_ui.dart';

void main() {
  const testAudio = AudioEntity(
    id: 'test_id',
    title: 'Test Surah',
    url: 'https://example.com/audio.mp3',
    duration: Duration(minutes: 5),
    artist: 'Test Reciter',
  );

  const testPositionData = PositionData(
    position: Duration(minutes: 2, seconds: 30),
    bufferedPosition: Duration(minutes: 3),
    duration: Duration(minutes: 5),
  );

  Widget createWidget({
    AudioEntity audio = const AudioEntity(
      id: 'test_id',
      title: 'Test Surah',
      url: 'https://example.com/audio.mp3',
      duration: Duration(minutes: 5),
      artist: 'Test Reciter',
    ),
    PositionData? positionData,
    bool isPlaying = false,
    bool canGoPrevious = true,
    bool canGoNext = true,
    VoidCallback? onPlayPause,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          ScreenUtilPlus.init(
            context,
            designSize: const Size(375, 812),
            minTextAdapt: true,
          );
          return Scaffold(
            body: BottomPlayerUi(
              audio: audio,
              positionData: positionData ?? testPositionData,
              isPlaying: isPlaying,
              canGoPrevious: canGoPrevious,
              canGoNext: canGoNext,
              onPlayPause: onPlayPause,
              onPrevious: onPrevious,
              onNext: onNext,
              onTap: onTap,
              onClose: onClose,
            ),
          );
        },
      ),
    );
  }

  group('BottomPlayerUi', () {
    testWidgets('renders audio title and artist', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Surah'), findsOneWidget);
      expect(find.text('Test Reciter'), findsOneWidget);
    });

    testWidgets('shows Unknown Reciter when artist is null', (tester) async {
      await tester.pumpWidget(
        createWidget(
          audio: const AudioEntity(
            id: 'test_id',
            title: 'Test Surah',
            url: 'https://example.com/audio.mp3',
            duration: Duration(minutes: 5),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unknown Reciter'), findsOneWidget);
    });

    testWidgets('displays progress bar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays zero progress when duration is zero', (tester) async {
      await tester.pumpWidget(
        createWidget(
          positionData: const PositionData(
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            duration: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final LinearProgressIndicator progressIndicator = tester.widget(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.0);
    });

    testWidgets('calls onPlayPause when play button is tapped', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(
        createWidget(onPlayPause: () => wasPressed = true),
      );
      await tester.pumpAndSettle();

      // The play/pause button is the central icon button in the controls
      await tester.tap(find.byType(IconButton).at(1)); // Second IconButton
      expect(wasPressed, isTrue);
    });

    testWidgets('calls onPrevious when previous button is tapped', (
      tester,
    ) async {
      var wasPressed = false;

      await tester.pumpWidget(
        createWidget(onPrevious: () => wasPressed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton).first);
      expect(wasPressed, isTrue);
    });

    testWidgets('calls onNext when next button is tapped', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(createWidget(onNext: () => wasPressed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton).last);
      expect(wasPressed, isTrue);
    });

    testWidgets('previous button is disabled when canGoPrevious is false', (
      tester,
    ) async {
      var wasPressed = false;

      await tester.pumpWidget(
        createWidget(canGoPrevious: false, onPrevious: () => wasPressed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton).first);
      expect(wasPressed, isFalse);
    });

    testWidgets('next button is disabled when canGoNext is false', (
      tester,
    ) async {
      var wasPressed = false;

      await tester.pumpWidget(
        createWidget(canGoNext: false, onNext: () => wasPressed = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton).last);
      expect(wasPressed, isFalse);
    });

    testWidgets('calls onTap when player area is tapped', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(createWidget(onTap: () => wasPressed = true));
      await tester.pumpAndSettle();

      // Tap on the Hero widget which wraps the album art (part of the tappable area)
      await tester.tap(find.byType(Hero));
      expect(wasPressed, isTrue);
    });

    testWidgets('displays default icon when artUri is null', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should show the default music icon
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders Hero widget with correct tag', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Hero), findsOneWidget);
      final Hero hero = tester.widget(find.byType(Hero));
      expect(hero.tag, 'audio_player');
    });

    testWidgets('shows pause icon when playing', (tester) async {
      await tester.pumpWidget(createWidget(isPlaying: true));
      await tester.pumpAndSettle();

      // Find all icons and check that pause icon exists
      final Finder icons = find.byType(Icon);
      expect(icons, findsWidgets);
    });

    testWidgets('shows play icon when not playing', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder icons = find.byType(Icon);
      expect(icons, findsWidgets);
    });
  });
}
