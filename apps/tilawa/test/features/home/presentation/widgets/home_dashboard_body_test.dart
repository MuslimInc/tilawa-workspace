import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_body.dart';
import 'package:tilawa/features/home/presentation/widgets/home_daily_ayah_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_features_hub.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockHomeQuranResumeCubit extends MockCubit<HomeQuranResumeState>
    implements HomeQuranResumeCubit {}

class _MockHomeListeningResumeCubit extends MockCubit<HomeListeningResumeState>
    implements HomeListeningResumeCubit {}

class _MockHomeAthkarCompactCubit extends MockCubit<HomeAthkarCompactState>
    implements HomeAthkarCompactCubit {}

class _MockHomePrimaryActionCubit extends MockCubit<HomePrimaryActionState>
    implements HomePrimaryActionCubit {}

void main() {
  testWidgets('shows primary action, feature hub, and today ayah', (
    tester,
  ) async {
    final quranCubit = _MockHomeQuranResumeCubit();
    when(() => quranCubit.state).thenReturn(const HomeQuranResumeState());
    when(() => quranCubit.stream).thenAnswer((_) => const Stream.empty());

    final listeningCubit = _MockHomeListeningResumeCubit();
    when(
      () => listeningCubit.state,
    ).thenReturn(const HomeListeningResumeState());
    when(() => listeningCubit.stream).thenAnswer((_) => const Stream.empty());

    final athkarCubit = _MockHomeAthkarCompactCubit();
    when(() => athkarCubit.state).thenReturn(const HomeAthkarCompactState());
    when(() => athkarCubit.stream).thenAnswer((_) => const Stream.empty());

    final primaryCubit = _MockHomePrimaryActionCubit();
    when(() => primaryCubit.state).thenReturn(const HomePrimaryActionState());
    when(() => primaryCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MultiBlocProvider(
              providers: [
                BlocProvider<HomeQuranResumeCubit>.value(value: quranCubit),
                BlocProvider<HomeListeningResumeCubit>.value(
                  value: listeningCubit,
                ),
                BlocProvider<HomeAthkarCompactCubit>.value(value: athkarCubit),
                BlocProvider<HomePrimaryActionCubit>.value(
                  value: primaryCubit,
                ),
              ],
              child: HomeDashboardBody(onOpenPrayer: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeDashboardBody)),
    );

    expect(find.text(l10n.homeTodayTitle), findsOneWidget);
    expect(find.text(l10n.homeYoursTitle), findsNothing);
    expect(find.byType(HomeDailyAyahCard), findsOneWidget);
    expect(find.byType(HomePrimaryActionCard), findsOneWidget);
    expect(find.byType(HomeFeaturesHub), findsOneWidget);
    expect(find.text(l10n.homeExploreTitle), findsOneWidget);
    expect(find.text(l10n.homeQuickAthkar), findsWidgets);
    expect(find.text(l10n.homeQuickQibla), findsWidgets);
    expect(find.text(l10n.homeQuickTasbeeh), findsWidgets);
    expect(find.text(l10n.bookmarks), findsOneWidget);

    expect(find.text(l10n.homePrayerStripTitle), findsNothing);
    expect(find.text(l10n.homePrayerStripViewAll), findsNothing);
  });
}
