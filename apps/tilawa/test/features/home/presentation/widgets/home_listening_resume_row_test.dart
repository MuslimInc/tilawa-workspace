import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_listening_resume_row.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('shows percent and progress bar when duration is known', (
    tester,
  ) async {
    final cubit = _FakeListeningResumeCubit(
      const HomeListeningResumeState(
        status: HomeListeningResumeStatus.ready,
        reciterName: 'Al-Afasy',
        surahName: 'Al-Fatihah',
        audioUrl: 'https://example.com/audio.mp3',
        lastPositionMs: 30000,
        durationMs: 120000,
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<HomeListeningResumeCubit>.value(
            value: cubit,
            child: const HomeListeningResumeRow(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeListeningResumeRow)),
    );
    final String base = l10n.homeListeningResumeSubtitle(
      'Al-Afasy',
      'Al-Fatihah',
    );
    expect(
      find.text('$base · ${l10n.homeListeningResumePercent(25)}'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text(l10n.continueListening), findsOneWidget);
  });

  testWidgets('hides progress cue when duration is unknown', (tester) async {
    final cubit = _FakeListeningResumeCubit(
      const HomeListeningResumeState(
        status: HomeListeningResumeStatus.ready,
        reciterName: 'Al-Afasy',
        surahName: 'Al-Fatihah',
        audioUrl: 'https://example.com/audio.mp3',
        lastPositionMs: 30000,
        durationMs: 0,
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<HomeListeningResumeCubit>.value(
            value: cubit,
            child: const HomeListeningResumeRow(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeListeningResumeRow)),
    );
    expect(
      find.text(l10n.homeListeningResumeSubtitle('Al-Afasy', 'Al-Fatihah')),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}

class _FakeListeningResumeCubit extends Cubit<HomeListeningResumeState>
    implements HomeListeningResumeCubit {
  _FakeListeningResumeCubit(super.initialState);

  @override
  Future<void> load() async {}
}
