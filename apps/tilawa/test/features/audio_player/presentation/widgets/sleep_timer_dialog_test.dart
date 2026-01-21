import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/sleep_timer_dialog.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/shared/models/position_data.dart';

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

void main() {
  late AudioPlayerBloc mockAudioPlayerBloc;

  setUpAll(() {
    registerFallbackValue(const AudioPlayerEvent.cancelSleepTimer());
  });

  setUp(() {
    mockAudioPlayerBloc = MockAudioPlayerBloc();
    when(
      () => mockAudioPlayerBloc.state,
    ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.initial));
  });

  Future<void> pumpDialog(WidgetTester tester, Widget child) async {
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Base')),
          routes: [
            GoRoute(
              path: 'dialog',
              builder: (context, state) => Scaffold(body: Center(child: child)),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1080, 1920),
        builder: (context, _) => BlocProvider<AudioPlayerBloc>.value(
          value: mockAudioPlayerBloc,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );

    await tester.pump();
    router.go('/dialog');
    await tester.pumpAndSettle();
  }

  group('SleepTimerDialog', () {
    testWidgets('renders correctly when timer is inactive', (tester) async {
      await pumpDialog(tester, const SleepTimerDialog());

      // Note: recitationDuration is "مدة التلاوة" in app_en.arb
      expect(find.text('مدة التلاوة'), findsOneWidget);
      expect(find.text('15 Minutes'), findsOneWidget);
      expect(find.text('30 Minutes'), findsOneWidget);
      expect(find.text('60 Minutes'), findsOneWidget);
      expect(find.text('End of Track'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Active'), findsNothing);

      // Line 125: Tapping Cancel when inactive
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(SleepTimerDialog), findsNothing);
    });

    testWidgets('renders active state correctly', (tester) async {
      when(() => mockAudioPlayerBloc.state).thenReturn(
        AudioPlayerState(
          status: AudioPlayerStatus.success,
          sleepTimerTargetTime: DateTime.now().add(const Duration(minutes: 15)),
          lastSleepTimerDuration: const Duration(minutes: 15),
        ),
      );

      await pumpDialog(tester, const SleepTimerDialog());

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Cancel Timer'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('tapping 15 min chip adds event and pops', (tester) async {
      await pumpDialog(tester, const SleepTimerDialog());

      await tester.tap(find.text('15 Minutes'));
      await tester.pumpAndSettle();

      verify(
        () => mockAudioPlayerBloc.add(
          const AudioPlayerEvent.setSleepTimer(Duration(minutes: 15)),
        ),
      ).called(1);
    });

    testWidgets('tapping End of Track chip adds event when duration is known', (
      tester,
    ) async {
      when(() => mockAudioPlayerBloc.state).thenReturn(
        const AudioPlayerState(
          status: AudioPlayerStatus.success,
          positionData: PositionData(
            position: Duration(minutes: 5),
            bufferedPosition: Duration(minutes: 10),
            duration: Duration(minutes: 20),
          ),
        ),
      );

      await pumpDialog(tester, const SleepTimerDialog());

      await tester.tap(find.text('End of Track'));
      await tester.pumpAndSettle();

      verify(
        () => mockAudioPlayerBloc.add(
          const AudioPlayerEvent.setSleepTimer(Duration(minutes: 15)),
        ),
      ).called(1);
    });

    testWidgets('End of Track chip is disabled when duration is unknown', (
      tester,
    ) async {
      when(
        () => mockAudioPlayerBloc.state,
      ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.success));

      await pumpDialog(tester, const SleepTimerDialog());

      final ActionChip chip = tester.widget<ActionChip>(
        find.ancestor(
          of: find.text('End of Track'),
          matching: find.byType(ActionChip),
        ),
      );
      expect(chip.onPressed, isNull);
    });

    testWidgets('renders End of Track as active (Lines 188, 192)', (
      tester,
    ) async {
      const remaining = Duration(minutes: 15);
      when(() => mockAudioPlayerBloc.state).thenReturn(
        AudioPlayerState(
          status: AudioPlayerStatus.success,
          sleepTimerTargetTime: DateTime.now().add(remaining),
          lastSleepTimerDuration: remaining,
          positionData: const PositionData(
            position: Duration(minutes: 5),
            bufferedPosition: Duration(minutes: 10),
            duration: Duration(minutes: 20),
          ),
        ),
      );

      await pumpDialog(tester, const SleepTimerDialog());

      final ActionChip chip = tester.widget<ActionChip>(
        find.ancestor(
          of: find.text('End of Track'),
          matching: find.byType(ActionChip),
        ),
      );
      expect(
        chip.backgroundColor,
        Theme.of(tester.element(find.byType(SleepTimerDialog))).primaryColor,
      );
    });

    testWidgets('renders Custom as active (Lines 240, 244)', (tester) async {
      when(() => mockAudioPlayerBloc.state).thenReturn(
        AudioPlayerState(
          status: AudioPlayerStatus.success,
          sleepTimerTargetTime: DateTime.now().add(const Duration(minutes: 45)),
          lastSleepTimerDuration: const Duration(minutes: 45),
        ),
      );

      await pumpDialog(tester, const SleepTimerDialog());

      final ActionChip chip = tester.widget<ActionChip>(
        find.ancestor(
          of: find.text('Custom'),
          matching: find.byType(ActionChip),
        ),
      );
      expect(
        chip.backgroundColor,
        Theme.of(tester.element(find.byType(SleepTimerDialog))).primaryColor,
      );
    });

    testWidgets('tapping Cancel Sleep Timer adds cancel event', (tester) async {
      when(() => mockAudioPlayerBloc.state).thenReturn(
        AudioPlayerState(
          status: AudioPlayerStatus.success,
          sleepTimerTargetTime: DateTime.now().add(const Duration(minutes: 15)),
          lastSleepTimerDuration: const Duration(minutes: 15),
        ),
      );

      await pumpDialog(tester, const SleepTimerDialog());

      await tester.tap(find.text('Cancel Timer'));
      await tester.pumpAndSettle();

      verify(
        () =>
            mockAudioPlayerBloc.add(const AudioPlayerEvent.cancelSleepTimer()),
      ).called(1);
    });

    testWidgets('Custom duration picker works', (tester) async {
      await pumpDialog(tester, const SleepTimerDialog());

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.text('Set Timer'), findsOneWidget);
      expect(find.text('Hour'), findsWidgets);
      expect(find.text('Minute'), findsWidgets);

      // Save default custom (15 min)
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => mockAudioPlayerBloc.add(
          const AudioPlayerEvent.setSleepTimer(Duration(minutes: 15)),
        ),
      ).called(1);
    });

    testWidgets(
      'Custom duration picker scrolling (Lines 325, 326, 382-385, 439)',
      (tester) async {
        await pumpDialog(tester, const SleepTimerDialog());

        await tester.tap(find.text('Custom'));
        await tester.pumpAndSettle();

        // Scroll the minute picker
        // We find the minute picker wheel - it's the second ListWheelScrollView
        final Finder minutePicker = find.byType(ListWheelScrollView).last;
        await tester.drag(minutePicker, const Offset(0, -200));
        await tester.pumpAndSettle();

        // Verify save triggers event with different duration
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        verify(
          () => mockAudioPlayerBloc.add(
            any(
              that: isA<AudioPlayerEvent>().having(
                (e) {
                  if (e is SetSleepTimer) {
                    return e.duration != const Duration(minutes: 15);
                  }
                  return false;
                },
                'is not default',
                true,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('Custom duration picker cancellation', (tester) async {
      await pumpDialog(tester, const SleepTimerDialog());

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Set Timer'), findsNothing);
      verifyNever(() => mockAudioPlayerBloc.add(any()));
    });
  });
}
