import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_index_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _FakeGetLastReadPosition implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return const Right((surahNumber: null, ayahNumber: null, page: null));
  }
}

Widget _wrapQuranIndex(Widget child) {
  final GoRouter router = GoRouter(
    initialLocation: '/quran-index',
    routes: <RouteBase>[
      GoRoute(
        path: '/quran-index',
        builder: (context, state) => child,
      ),
    ],
  );

  return ChangeNotifierProvider<QuranPlayerChromeNotifier>(
    create: (_) => QuranPlayerChromeNotifier(),
    child: MaterialApp.router(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('shows Quran hub title, catalog pills, and surah rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapQuranIndex(
        BlocProvider(
          create: (_) => HomeQuranResumeCubit(
            _FakeGetLastReadPosition(),
            _FakeHistoryRepository(),
          )..load(),
          child: const QuranIndexScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(QuranIndexScreen)),
    );

    expect(find.text(l10n.quranHubTitle), findsOneWidget);
    expect(find.text(l10n.surahPrefix), findsOneWidget);
    expect(find.text(l10n.juz), findsOneWidget);
    expect(find.text(l10n.page), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);
  });
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
