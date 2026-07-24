import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_tile.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_actions_section.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('Quran tile shows resume surah and page when last read exists', (
    tester,
  ) async {
    final cubit = HomeQuranResumeCubit(
      _FixedGetLastRead(surahNumber: 2, page: 5),
      _FakeHistoryRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<HomeQuranResumeCubit>.value(
            value: cubit,
            child: const HomePrimaryActionsSection(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomePrimaryActionsSection)),
    );
    final String expected = l10n.homeQuranResumeSurahPage(
      SurahNames.getEnglishSurahName(2),
      5,
    );

    expect(find.byType(HomePrimaryActionTile), findsNWidgets(2));
    expect(find.text(l10n.homeAthkarAll), findsOneWidget);
    expect(find.text(expected), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('Quran tile shows page-1 resume as underway progress', (
    tester,
  ) async {
    final cubit = HomeQuranResumeCubit(
      _FixedGetLastRead(surahNumber: 1, page: 1),
      _FakeHistoryRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<HomeQuranResumeCubit>.value(
            value: cubit,
            child: const HomePrimaryActionsSection(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomePrimaryActionsSection)),
    );
    final String expected = l10n.homeQuranResumeSurahPage(
      SurahNames.getEnglishSurahName(1),
      1,
    );
    expect(find.text(l10n.homeQuickQuranReader), findsOneWidget);
    expect(find.text(expected), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('Athkar tile shows contextual start copy without progress', (
    tester,
  ) async {
    const AthkarCategory morning = AthkarCategory(
      id: 1,
      nameAr: 'أذكار الصباح',
      nameEn: 'Morning Athkar',
      icon: 'wb_sunny_rounded',
    );
    const AthkarCategory evening = AthkarCategory(
      id: 2,
      nameAr: 'أذكار المساء',
      nameEn: 'Evening Athkar',
      icon: 'nights_stay_rounded',
    );
    const AthkarCategory sleep = AthkarCategory(
      id: 3,
      nameAr: 'أذكار النوم',
      nameEn: 'Sleep Athkar',
      icon: 'bedtime_rounded',
    );
    final athkarCubit = _FakeAthkarCompactCubit(
      const HomeAthkarCompactState(
        status: HomeAthkarRowStatus.ready,
        rows: <HomeAthkarRowState>[
          HomeAthkarRowState(
            category: morning,
            completion: HomeAthkarCompletionState.inProgress,
            remainingCount: 3,
            totalRequired: 10,
          ),
          HomeAthkarRowState(
            category: evening,
            completion: HomeAthkarCompletionState.inProgress,
            remainingCount: 3,
            totalRequired: 10,
          ),
          HomeAthkarRowState(
            category: sleep,
            completion: HomeAthkarCompletionState.inProgress,
            remainingCount: 3,
            totalRequired: 10,
          ),
        ],
      ),
    );
    addTearDown(athkarCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<HomeAthkarCompactCubit>.value(
            value: athkarCubit,
            child: const HomePrimaryActionsSection(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomePrimaryActionsSection)),
    );
    expect(find.text(l10n.homeAthkarRemaining(3)), findsNothing);
    expect(find.text(l10n.homeAthkarAll), findsOneWidget);
    expect(find.text(l10n.homeAthkarSleepStart), findsNothing);
    expect(find.text(l10n.homeAthkarMorningStart), findsNothing);
    expect(find.text(l10n.homeAthkarEveningStart), findsNothing);
    expect(
      find.text('Morning Athkar').evaluate().isNotEmpty ||
          find.text('Evening Athkar').evaluate().isNotEmpty ||
          find.text('Sleep Athkar').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('Athkar tile deep-links to recommended category details', (
    tester,
  ) async {
    const AthkarCategory morning = AthkarCategory(
      id: 1,
      nameAr: 'أذكار الصباح',
      nameEn: 'Morning Athkar',
      icon: 'wb_sunny_rounded',
    );
    const AthkarCategory evening = AthkarCategory(
      id: 2,
      nameAr: 'أذكار المساء',
      nameEn: 'Evening Athkar',
      icon: 'nights_stay_rounded',
    );
    const AthkarCategory sleep = AthkarCategory(
      id: 3,
      nameAr: 'أذكار النوم',
      nameEn: 'Sleep Athkar',
      icon: 'bedtime_rounded',
    );
    final athkarCubit = _FakeAthkarCompactCubit(
      const HomeAthkarCompactState(
        status: HomeAthkarRowStatus.ready,
        rows: <HomeAthkarRowState>[
          HomeAthkarRowState(
            category: morning,
            completion: HomeAthkarCompletionState.inProgress,
            remainingCount: 3,
            totalRequired: 10,
          ),
          HomeAthkarRowState(category: evening),
          HomeAthkarRowState(category: sleep),
        ],
      ),
    );
    addTearDown(athkarCubit.close);

    String? openedLocation;
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: BlocProvider<HomeAthkarCompactCubit>.value(
              value: athkarCubit,
              child: const HomePrimaryActionsSection(),
            ),
          ),
        ),
        GoRoute(
          path: '/athkar/:categoryId',
          builder: (context, state) {
            openedLocation = state.uri.toString();
            return const Scaffold(body: Text('Athkar details'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HomePrimaryActionTile).last);
    await tester.pumpAndSettle();

    expect(openedLocation, isNotNull);
    expect(openedLocation, contains('source=home_primary'));
    expect(
      openedLocation!.contains('/athkar/1') ||
          openedLocation!.contains('/athkar/2') ||
          openedLocation!.contains('/athkar/3'),
      isTrue,
    );
  });

  testWidgets('Athkar secondary CTA opens full library', (tester) async {
    const AthkarCategory morning = AthkarCategory(
      id: 1,
      nameAr: 'أذكار الصباح',
      nameEn: 'Morning Athkar',
      icon: 'wb_sunny_rounded',
    );
    final athkarCubit = _FakeAthkarCompactCubit(
      const HomeAthkarCompactState(
        status: HomeAthkarRowStatus.ready,
        rows: <HomeAthkarRowState>[
          HomeAthkarRowState(category: morning),
        ],
      ),
    );
    addTearDown(athkarCubit.close);

    String? openedLocation;
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: BlocProvider<HomeAthkarCompactCubit>.value(
              value: athkarCubit,
              child: const HomePrimaryActionsSection(),
            ),
          ),
        ),
        GoRoute(
          path: '/athkar',
          builder: (context, state) {
            openedLocation = state.uri.toString();
            return const Scaffold(body: Text('Athkar library'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomePrimaryActionsSection)),
    );
    await tester.tap(find.text(l10n.homeAthkarAll));
    await tester.pumpAndSettle();

    expect(openedLocation, contains('/athkar'));
    expect(find.text('Athkar library'), findsOneWidget);
  });
}

class _FakeAthkarCompactCubit extends Cubit<HomeAthkarCompactState>
    implements HomeAthkarCompactCubit {
  _FakeAthkarCompactCubit(super.initialState);

  @override
  Future<void> load({DateTime? now}) async {}
}

class _FixedGetLastRead implements GetLastReadPositionUseCase {
  _FixedGetLastRead({required this.surahNumber, required this.page});

  final int surahNumber;
  final int page;

  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return Right((surahNumber: surahNumber, ayahNumber: 1, page: page));
  }
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<HistoryEntity>> getRecentHistory({int limit = 20}) async => [];

  @override
  Future<List<HistoryEntity>> getAllHistory() async => [];

  @override
  Future<HistoryEntity> addOrUpdateHistory({
    required int surahId,
    required String surahName,
    required String surahNameEn,
    required String reciterId,
    required String reciterName,
    required int moshafId,
    required String moshafName,
    required int lastPositionMs,
    required int durationMs,
    required String audioUrl,
    String? artworkUrl,
    bool completed = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAllHistory() async {}

  @override
  Future<void> deleteHistory(String id) async {}

  @override
  Future<HistoryEntity?> getHistoryById(String id) async => null;

  @override
  Future<List<HistoryEntity>> getHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async => [];

  @override
  Future<List<HistoryEntity>> getHistoryByReciter(String reciterId) async => [];

  @override
  Future<HistoryEntity?> updateLastPosition({
    required String id,
    required int lastPositionMs,
    bool? completed,
  }) async => null;

  @override
  Future<void> deleteHistoryOlderThan(DateTime date) async {}

  @override
  Future<List<HistoryEntity>> searchHistory(String query) async => [];

  @override
  Future<int> getHistoryCount() async => 0;

  @override
  Future<int> getTotalListeningTime() async => 0;

  @override
  Future<List<HistoryEntity>> getMostPlayedSurahs({int limit = 10}) async => [];

  @override
  Future<bool> hasBeenPlayed({
    required int surahId,
    required String reciterId,
    required int moshafId,
  }) async => false;
}
