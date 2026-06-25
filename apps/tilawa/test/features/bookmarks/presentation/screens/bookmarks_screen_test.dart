import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/bookmarks/domain/entities/bookmark_entity.dart';
import 'package:tilawa/features/bookmarks/presentation/bloc/bookmarks_bloc.dart';
import 'package:tilawa/core/layout/list_scroll_bottom_padding.dart';
import 'package:tilawa/features/bookmarks/presentation/screens/bookmarks_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MockBookmarksBloc extends MockBloc<BookmarksEvent, BookmarksState>
    implements BookmarksBloc {}

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

BookmarkEntity _sampleBookmark() {
  return BookmarkEntity(
    id: 'bookmark-1',
    surahId: 1,
    surahName: 'الفاتحة',
    surahNameEn: 'Al-Fatihah',
    reciterId: 'reciter-1',
    reciterName: 'Reciter',
    moshafId: 1,
    moshafName: 'Hafs',
    positionMs: 30_000,
    durationMs: 120_000,
    audioUrl: 'https://example.com/audio.mp3',
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: DateTime.utc(2024, 1, 2),
  );
}

Future<void> _pumpBookmarksScreen(
  WidgetTester tester, {
  required BookmarksState state,
  EdgeInsets viewInsets = EdgeInsets.zero,
  double shellPadding = 0,
}) async {
  final MockBookmarksBloc bookmarksBloc = MockBookmarksBloc();
  final MockAudioPlayerBloc audioPlayerBloc = MockAudioPlayerBloc();

  when(() => bookmarksBloc.state).thenReturn(state);
  when(() => bookmarksBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => audioPlayerBloc.state).thenReturn(
    const AudioPlayerState(status: AudioPlayerStatus.initial),
  );
  when(() => audioPlayerBloc.stream).thenAnswer((_) => const Stream.empty());

  final GoRouter router = GoRouter(
    initialLocation: '/bookmarks',
    routes: <RouteBase>[
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => TilawaShellPadding(
          padding: shellPadding,
          child: MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<BookmarksBloc>.value(value: bookmarksBloc),
              BlocProvider<AudioPlayerBloc>.value(value: audioPlayerBloc),
            ],
            child: const BookmarksScreen(),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(viewInsets: viewInsets),
      child: MaterialApp.router(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty bookmarks body scrolls and stays visible with keyboard', (
    tester,
  ) async {
    const double keyboardInset = 300;

    await _pumpBookmarksScreen(
      tester,
      state: const BookmarksState.loaded(
        bookmarks: <BookmarkEntity>[],
        filteredBookmarks: <BookmarkEntity>[],
      ),
      viewInsets: const EdgeInsets.only(bottom: keyboardInset),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(BookmarksScreen)),
    );

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.text(l10n.noBookmarks), findsOneWidget);

    final CustomScrollView scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(
      scrollView.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );

    final BuildContext screenContext = tester.element(
      find.byType(BookmarksScreen),
    );
    final MeMuslimDesignTokens tokens = Theme.of(screenContext).tokens;
    final double shellScrollPadding = listScrollBottomPadding(screenContext);

    final SliverPadding bottomSpacer = tester.widget<SliverPadding>(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(SliverPadding),
      ),
    );
    final EdgeInsets bottomPadding = bottomSpacer.padding.resolve(
      TextDirection.ltr,
    );
    expect(bottomPadding.bottom, tokens.spaceSmall);
    expect(bottomPadding.bottom, lessThan(shellScrollPadding));
  });

  testWidgets(
    'keyboard open omits shell player scroll bottom padding',
    (tester) async {
      const double shellPadding = 80;
      const double keyboardInset = 300;

      await _pumpBookmarksScreen(
        tester,
        state: const BookmarksState.loaded(
          bookmarks: <BookmarkEntity>[],
          filteredBookmarks: <BookmarkEntity>[],
        ),
        viewInsets: const EdgeInsets.only(bottom: keyboardInset),
        shellPadding: shellPadding,
      );

      final BuildContext screenContext = tester.element(
        find.byType(BookmarksScreen),
      );
      final MeMuslimDesignTokens tokens = Theme.of(screenContext).tokens;
      final double shellScrollPadding = listScrollBottomPadding(screenContext);

      final SliverPadding bottomSpacer = tester.widget<SliverPadding>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(SliverPadding),
        ),
      );
      final double bottomPadding = bottomSpacer.padding
          .resolve(TextDirection.ltr)
          .bottom;

      expect(shellScrollPadding, greaterThan(tokens.spaceSmall));
      expect(bottomPadding, tokens.spaceSmall);
      expect(bottomPadding, isNot(shellScrollPadding));
    },
  );

  testWidgets('populated bookmarks list uses scrollable sliver layout', (
    tester,
  ) async {
    final BookmarkEntity bookmark = _sampleBookmark();

    await _pumpBookmarksScreen(
      tester,
      state: BookmarksState.loaded(
        bookmarks: <BookmarkEntity>[bookmark],
        filteredBookmarks: <BookmarkEntity>[bookmark],
      ),
    );

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverList), findsOneWidget);
    expect(find.text(bookmark.surahName), findsOneWidget);
  });
}
