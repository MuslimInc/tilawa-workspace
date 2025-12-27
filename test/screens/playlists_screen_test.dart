import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';
import 'package:tilawa/features/playlists/presentation/bloc/playlists_bloc.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/playlists_screen.dart';

import '../router/router_mock_helper.mocks.dart';

void main() {
  late MockPlaylistsBloc mockPlaylistsBloc;

  Playlist createTestPlaylist({
    String id = '1',
    String name = 'Test Playlist',
  }) {
    return Playlist(
      id: id,
      name: name,
      description: 'Test Description',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: const [],
    );
  }

  setUp(() {
    mockPlaylistsBloc = MockPlaylistsBloc();

    provideDummy<PlaylistsState>(const PlaylistsState.initial());

    when(mockPlaylistsBloc.stream).thenAnswer((_) => const Stream.empty());
    // Default to empty loaded state to avoid CircularProgressIndicator timeouts
    when(
      mockPlaylistsBloc.state,
    ).thenReturn(const PlaylistsState.loaded(playlists: []));
  });

  Widget buildTestWidget() {
    return BlocProvider<PlaylistsBloc>.value(
      value: mockPlaylistsBloc,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaylistsScreen(),
      ),
    );
  }

  group('PlaylistsScreen', () {
    testWidgets('loads playlists on init', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      verify(mockPlaylistsBloc.add(const LoadPlaylistsEvent())).called(1);
    });

    testWidgets('shows loading indicator when state is loading', (
      tester,
    ) async {
      when(mockPlaylistsBloc.state).thenReturn(const PlaylistsState.loading());
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no playlists', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('No playlists yet'), findsOneWidget);
    });

    testWidgets('shows playlists list when loaded', (tester) async {
      final List<Playlist> playlists = [createTestPlaylist()];
      when(mockPlaylistsBloc.state).thenReturn(
        PlaylistsState.loaded(
          playlists: playlists,
          filteredPlaylists: playlists,
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      expect(find.text('Test Playlist'), findsOneWidget);
    });

    testWidgets('covers common list builder states', (tester) async {
      final List<Playlist> playlists = [createTestPlaylist()];

      final states = [
        PlaylistsState.playlistCreated(
          playlist: playlists[0],
          playlists: playlists,
        ),
        PlaylistsState.playlistUpdated(
          playlist: playlists[0],
          playlists: playlists,
        ),
        PlaylistsState.playlistDeleted(playlistId: '1', playlists: playlists),
        PlaylistsState.itemAdded(playlist: playlists[0], playlists: playlists),
        PlaylistsState.itemRemoved(
          playlist: playlists[0],
          playlists: playlists,
        ),
        PlaylistsState.itemsReordered(
          playlist: playlists[0],
          playlists: playlists,
        ),
        PlaylistsState.playlistDuplicated(
          playlist: playlists[0],
          playlists: playlists,
        ),
        PlaylistsState.favoriteToggled(
          playlist: playlists[0],
          playlists: playlists,
        ),
      ];

      for (final state in states) {
        when(mockPlaylistsBloc.state).thenReturn(state);
        await tester.pumpWidget(buildTestWidget());
        expect(find.text('Test Playlist'), findsOneWidget);
      }
    });

    testWidgets('shows error state and retries', (tester) async {
      when(
        mockPlaylistsBloc.state,
      ).thenReturn(const PlaylistsState.error('Test Error'));
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Test Error'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      // 1 from init, 1 from retry
      verify(mockPlaylistsBloc.add(const LoadPlaylistsEvent())).called(2);
    });

    testWidgets('search changed sends event', (tester) async {
      final List<Playlist> playlists = [createTestPlaylist()];
      when(mockPlaylistsBloc.state).thenReturn(
        PlaylistsState.loaded(
          playlists: playlists,
          filteredPlaylists: playlists,
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      final Finder searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Query');
      verify(
        mockPlaylistsBloc.add(const SearchPlaylistsEvent('Query')),
      ).called(1);
    });

    testWidgets('shows delete dialog and cancels', (tester) async {
      final List<Playlist> playlists = [createTestPlaylist()];
      when(mockPlaylistsBloc.state).thenReturn(
        PlaylistsState.loaded(
          playlists: playlists,
          filteredPlaylists: playlists,
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Playlist'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Playlist'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Playlist'), findsNothing);
    });

    testWidgets('shows delete dialog and deletes', (tester) async {
      final List<Playlist> playlists = [createTestPlaylist()];
      when(mockPlaylistsBloc.state).thenReturn(
        PlaylistsState.loaded(
          playlists: playlists,
          filteredPlaylists: playlists,
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Playlist'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      verify(mockPlaylistsBloc.add(const DeletePlaylistEvent('1'))).called(1);
    });

    testWidgets('triggers other card actions', (tester) async {
      final List<Playlist> playlists = [createTestPlaylist(id: 'fav-1')];
      when(mockPlaylistsBloc.state).thenReturn(
        PlaylistsState.loaded(
          playlists: playlists,
          filteredPlaylists: playlists,
        ),
      );

      await tester.pumpWidget(buildTestWidget());

      // Favorite
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Favorites'));
      await tester.pumpAndSettle(); // Wait for menu to close
      verify(
        mockPlaylistsBloc.add(const ToggleFavoriteEvent('fav-1')),
      ).called(1);
      await tester.pumpAndSettle();

      // Play
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Playlist'));
      await tester.pumpAndSettle(); // Wait for menu to close

      // Edit
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Playlist'));
      await tester.pumpAndSettle(); // Menu closes

      // Navigate
      await tester.tap(find.text('Test Playlist'));
      await tester.pumpAndSettle();
    });

    testWidgets('listener handles toast messages', (tester) async {
      final List<Playlist> playlists = [createTestPlaylist()];
      final streamController = StreamController<PlaylistsState>.broadcast();
      when(mockPlaylistsBloc.stream).thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(buildTestWidget());

      streamController.add(
        PlaylistsState.playlistUpdated(
          playlist: playlists[0],
          playlists: playlists,
        ),
      );
      await tester.pump();

      streamController.add(
        PlaylistsState.playlistDeleted(playlistId: '1', playlists: playlists),
      );
      await tester.pump();

      streamController.add(
        PlaylistsState.favoriteToggled(
          playlist: playlists[0].copyWith(isFavorite: true),
          playlists: playlists,
        ),
      );
      await tester.pump();

      streamController.add(
        PlaylistsState.favoriteToggled(
          playlist: playlists[0].copyWith(isFavorite: false),
          playlists: playlists,
        ),
      );
      await tester.pump();

      streamController.add(const PlaylistsState.error('Toast Error'));
      await tester.pump();

      await streamController.close();
    });

    testWidgets('shows create playlist dialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Create New Playlist'), findsOneWidget);
    });

    testWidgets('refresh button sends event', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.byIcon(Icons.refresh));
      verify(mockPlaylistsBloc.add(const RefreshPlaylistsEvent())).called(1);
    });
  });
}
