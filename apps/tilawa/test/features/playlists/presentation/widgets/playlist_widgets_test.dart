import 'package:tilawa/test_support/screenutil_compat.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';
import 'package:tilawa/features/playlists/presentation/bloc/playlists_bloc.dart';
import 'package:tilawa/features/playlists/presentation/widgets/create_playlist_dialog.dart';
import 'package:tilawa/features/playlists/presentation/widgets/playlist_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockPlaylistsBloc extends MockBloc<PlaylistsEvent, PlaylistsState>
    implements PlaylistsBloc {}

void main() {
  late MockPlaylistsBloc mockPlaylistsBloc;

  setUpAll(() {
    registerFallbackValue(const LoadPlaylistsEvent());
  });

  setUp(() {
    mockPlaylistsBloc = MockPlaylistsBloc();
  });

  final tPlaylist = Playlist(
    id: '1',
    name: 'Test Playlist',
    description: 'Test Description',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    items: const [],
  );

  group('PlaylistCard', () {
    testWidgets('renders playlist info correctly', (tester) async {
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PlaylistCard(
                playlist: tPlaylist,
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
                onToggleFavorite: () {},
                onPlay: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Playlist'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('0 Items'), findsOneWidget);
    });

    testWidgets('calls callbacks when buttons pressed', (tester) async {
      var editCalled = false;
      var deleteCalled = false;
      var favoriteCalled = false;
      var playCalled = false;

      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(600, 1000), // Larger width to avoid overflow
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PlaylistCard(
                playlist: tPlaylist,
                onTap: () {},
                onEdit: () => editCalled = true,
                onDelete: () => deleteCalled = true,
                onToggleFavorite: () => favoriteCalled = true,
                onPlay: () => playCalled = true,
              ),
            ),
          ),
        ),
      );

      // Tap play button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Playlist'));
      await tester.pumpAndSettle();
      expect(playCalled, true);

      // Tap favorite button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Favorites'));
      await tester.pumpAndSettle();
      expect(favoriteCalled, true);

      // Open menu and tap edit
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Playlist'));
      await tester.pumpAndSettle();
      expect(editCalled, true);

      // Open menu and tap delete
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Playlist'));
      await tester.pumpAndSettle();
      expect(deleteCalled, true);
    });
  });

  group('CreatePlaylistDialog', () {
    testWidgets('dispatches CreatePlaylistEvent when valid data is submitted', (
      tester,
    ) async {
      when(
        () => mockPlaylistsBloc.state,
      ).thenReturn(const PlaylistsState.initial());

      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider<PlaylistsBloc>.value(
              value: mockPlaylistsBloc,
              child: const Scaffold(body: CreatePlaylistDialog()),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'New Playlist');
      await tester.enterText(
        find.byType(TextFormField).last,
        'New Description',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();

      verify(
        () => mockPlaylistsBloc.add(
          const CreatePlaylistEvent(
            name: 'New Playlist',
            description: 'New Description',
          ),
        ),
      ).called(1);
    });
  });
}
