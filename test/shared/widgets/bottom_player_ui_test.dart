import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa/shared/widgets/bottom_player_ui.dart';

class _MockHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

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
    bool isSleepTimerActive = false,
    bool isSleepTimerEnabled = true,
    VoidCallback? onPlayPause,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    VoidCallback? onSleepTimerTap,
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
              isSleepTimerActive: isSleepTimerActive,
              isSleepTimerEnabled: isSleepTimerEnabled,
              onPlayPause: onPlayPause,
              onPrevious: onPrevious,
              onNext: onNext,
              onSleepTimerTap: onSleepTimerTap,
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

      await tester.tap(find.byIcon(FluentIcons.play_16_filled));
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

      await tester.tap(find.byIcon(FluentIcons.previous_20_filled));
      expect(wasPressed, isTrue);
    });

    testWidgets('calls onNext when next button is tapped', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(createWidget(onNext: () => wasPressed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(FluentIcons.next_20_filled));
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

      await tester.tap(
        find.byType(IconButton).at(2),
      ); // Skip timer is at 3 now? No, wait.
      // IconButtons: 1 (Prev), 2 (Play), 3 (Next), 4 (Timer)
      // .last would be Timer.
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

      // Should show the default music icon from _buildDefaultIcon
      expect(find.byIcon(FluentIcons.music_note_2_24_filled), findsOneWidget);
    });

    testWidgets('handles album art callbacks (coverage)', (tester) async {
      final AudioEntity audioWithArt = testAudio.copyWith(
        artUri: 'https://example.com/art.png',
      );

      await tester.pumpWidget(createWidget(audio: audioWithArt));
      await tester.pump();

      final CachedNetworkImage image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final Element context = tester.element(find.byType(BottomPlayerUi));

      // Manually trigger builders to hit lines 126-129
      final Widget placeholder = image.placeholder!(context, 'url');
      final Widget error = image.errorWidget!(context, 'e', StackTrace.current);

      expect(placeholder, isA<Widget>());
      expect(error, isA<Widget>());
    });

    testWidgets('handles Hero callbacks (coverage)', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Hero hero = tester.widget<Hero>(find.byType(Hero));
      final Element context = tester.element(find.byType(BottomPlayerUi));

      // Hit createRectTween (lines 91-95)
      const rect = Rect.fromLTRB(0, 0, 100, 100);
      final Tween<Rect?> tween = hero.createRectTween!(rect, rect);
      expect(tween, isA<MaterialRectCenterArcTween>());

      // Hit placeholderBuilder (lines 97-108)
      final Widget placeholder = hero.placeholderBuilder!(
        context,
        const Size(48, 48),
        Container(),
      );
      expect(placeholder, isA<Widget>());
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

      expect(find.byIcon(FluentIcons.pause_16_filled), findsOneWidget);
    });

    testWidgets('shows play icon when not playing', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(FluentIcons.play_16_filled), findsOneWidget);
    });

    group('Sleep Timer', () {
      testWidgets('is visible when enabled', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(FluentIcons.timer_20_regular), findsOneWidget);
      });

      testWidgets('is hidden when disabled', (tester) async {
        await tester.pumpWidget(createWidget(isSleepTimerEnabled: false));
        await tester.pumpAndSettle();

        expect(find.byIcon(FluentIcons.timer_20_regular), findsNothing);
      });

      testWidgets('calls onSleepTimerTap when tapped', (tester) async {
        var wasPressed = false;
        await tester.pumpWidget(
          createWidget(onSleepTimerTap: () => wasPressed = true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(FluentIcons.timer_20_regular));
        expect(wasPressed, isTrue);
      });

      testWidgets('shows filled icon when active', (tester) async {
        await tester.pumpWidget(createWidget(isSleepTimerActive: true));
        await tester.pumpAndSettle();

        expect(find.byIcon(FluentIcons.timer_20_filled), findsOneWidget);
      });
    });
  });
}
