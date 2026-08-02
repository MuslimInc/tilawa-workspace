import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/history/presentation/bloc/history_bloc.dart';
import 'package:tilawa/features/history/presentation/screens/history_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockHistoryBloc extends MockBloc<HistoryEvent, HistoryState>
    implements HistoryBloc {}

class _MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

void main() {
  testWidgets(
    'empty history paints without LayoutBuilder intrinsic crash',
    (WidgetTester tester) async {
      final _MockHistoryBloc historyBloc = _MockHistoryBloc();
      final _MockAudioPlayerBloc audioPlayerBloc = _MockAudioPlayerBloc();
      const HistoryState emptyState = HistoryState(
        status: HistoryStatus.empty,
      );

      when(() => historyBloc.state).thenReturn(emptyState);
      when(() => historyBloc.stream).thenAnswer(
        (_) => Stream<HistoryState>.value(emptyState),
      );
      when(() => audioPlayerBloc.state).thenReturn(
        const AudioPlayerState(status: AudioPlayerStatus.initial),
      );
      when(() => audioPlayerBloc.stream).thenAnswer(
        (_) => const Stream<AudioPlayerState>.empty(),
      );

      FlutterErrorDetails? caught;
      final void Function(FlutterErrorDetails)? old = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        caught ??= details;
        old?.call(details);
      };
      addTearDown(() => FlutterError.onError = old);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<HistoryBloc>.value(value: historyBloc),
              BlocProvider<AudioPlayerBloc>.value(value: audioPlayerBloc),
            ],
            child: const HistoryScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(caught, isNull, reason: caught?.exceptionAsString());
      expect(tester.takeException(), isNull);
      expect(find.byType(TilawaEmptyState), findsOneWidget);
    },
  );
}
