import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_daily_inspiration_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_body.dart';
import 'package:tilawa/features/home/presentation/widgets/home_discover_shortcuts.dart';
import 'package:tilawa/features/home/presentation/widgets/home_more_actions_group.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_today_section.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/cubit/main_screen_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockHomeQuranResumeCubit extends MockCubit<HomeQuranResumeState>
    implements HomeQuranResumeCubit {}

class _MockHomeListeningResumeCubit extends MockCubit<HomeListeningResumeState>
    implements HomeListeningResumeCubit {}

class _MockHomeAthkarCompactCubit extends MockCubit<HomeAthkarCompactState>
    implements HomeAthkarCompactCubit {}

class _MockHomePrimaryActionCubit extends MockCubit<HomePrimaryActionState>
    implements HomePrimaryActionCubit {}

class _MockPinnedAthkarCubit extends MockCubit<PinnedAthkarState>
    implements PinnedAthkarCubit {}

class _MockMainScreenCubit extends MockCubit<MainScreenState>
    implements MainScreenCubit {}

void main() {
  testWidgets('shows primary action, daily practice, inspiration, and more', (
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

    final mainScreenCubit = _MockMainScreenCubit();
    when(() => mainScreenCubit.state).thenReturn(const MainScreenState());
    when(() => mainScreenCubit.stream).thenAnswer((_) => const Stream.empty());

    final pinnedAthkarCubit = _MockPinnedAthkarCubit();
    when(() => pinnedAthkarCubit.state).thenReturn(const PinnedAthkarState());
    when(() => pinnedAthkarCubit.stream).thenAnswer(
      (_) => const Stream.empty(),
    );

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
                BlocProvider<MainScreenCubit>.value(value: mainScreenCubit),
                BlocProvider<PinnedAthkarCubit>.value(value: pinnedAthkarCubit),
              ],
              child: const HomeDashboardBody(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeDashboardBody)),
    );

    expect(find.byType(HomePrimaryActionCard), findsOneWidget);
    expect(find.byType(HomeDiscoverShortcuts), findsOneWidget);
    expect(find.byType(HomeDailyPracticeSection), findsOneWidget);
    expect(find.byType(HomeDailyInspirationSection), findsOneWidget);
    expect(find.byType(HomeMoreActionsGroup), findsOneWidget);

    final double primaryTop = tester
        .getTopLeft(find.byType(HomePrimaryActionCard))
        .dy;
    final double practiceTop = tester
        .getTopLeft(find.byType(HomeDailyPracticeSection))
        .dy;
    final double inspirationTop = tester
        .getTopLeft(find.byType(HomeDailyInspirationSection))
        .dy;
    final double discoverTop = tester
        .getTopLeft(find.byType(HomeDiscoverShortcuts))
        .dy;
    final double moreTop = tester
        .getTopLeft(find.byType(HomeMoreActionsGroup))
        .dy;

    expect(primaryTop, lessThan(practiceTop));
    expect(practiceTop, lessThan(inspirationTop));
    expect(inspirationTop, lessThan(discoverTop));
    expect(discoverTop, lessThan(moreTop));

    // Today zone uses the canonical daily practice title, not the old
    // "Today: Prayer, Quran, and dhikr" mismatched wrapper.
    expect(find.text(l10n.homeAthkarRitualsTitle), findsOneWidget);
    expect(find.text(l10n.homeTodayTitle), findsNothing);

    // Discover shortcuts keep supporting tools available after the daily
    // practice and inspiration surfaces.
    expect(find.text(l10n.homeQuickReciters), findsOneWidget);
    expect(find.text(l10n.homeQuickQibla), findsOneWidget);
    expect(find.text(l10n.homeQuickTasbeeh), findsOneWidget);
    expect(find.text(l10n.bookmarks), findsOneWidget);

    // Nav-duplicate tiles must not appear on Home.
    expect(find.text(l10n.homeQuickPrayer), findsNothing);
    expect(find.text(l10n.homeQuickAthkar), findsNothing);
    expect(find.text(l10n.homeQuickQuran), findsNothing);

    // Secondary More list holds library destinations (no subtitle on Reciters
    // row anymore — Reciters is in Discover shortcuts grid).
    expect(find.text(l10n.listeningHistory), findsOneWidget);
    expect(find.text(l10n.favorites), findsOneWidget);

    // Inspiration zone shows the daily ayah label.
    expect(find.text(l10n.homeDailyAyahLabel), findsOneWidget);
  });
}
