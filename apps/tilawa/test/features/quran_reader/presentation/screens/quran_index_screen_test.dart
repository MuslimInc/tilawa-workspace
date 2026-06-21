import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
          create: (_) =>
              HomeQuranResumeCubit(_FakeGetLastReadPosition())..load(),
          child: const QuranIndexScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(QuranIndexScreen)),
    );

    expect(find.text(l10n.quranHubTitle), findsOneWidget);
    expect(find.text(l10n.quranCatalogSectionTitle), findsOneWidget);
    expect(find.text(l10n.surahPrefix), findsOneWidget);
    expect(find.text(l10n.juz), findsOneWidget);
    expect(find.text(l10n.page), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);
  });
}
