import 'package:tilawa/test_support/screenutil_compat.dart';
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';
import 'package:tilawa/features/playlists/presentation/bloc/playlists_bloc.dart';
import 'package:tilawa/features/playlists/presentation/widgets/create_playlist_dialog.dart';
import 'package:tilawa/features/playlists/presentation/widgets/playlist_card.dart';
import 'package:tilawa/features/playlists/presentation/widgets/playlist_search_bar.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/playlists_screen.dart';

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

  Widget createWidgetUnderTest() {
    return ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      child: BlocProvider<PlaylistsBloc>.value(
        value: mockPlaylistsBloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlaylistsScreen(),
        ),
      ),
    );
  }

  final tPlaylist = Playlist(
    id: '1',
    name: 'Test Playlist',
    description: 'Test Description',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    items: const [],
  );

  testWidgets('renders loading indicator when state is loading', (
    tester,
  ) async {
    when(
      () => mockPlaylistsBloc.state,
    ).thenReturn(const PlaylistsState.loading());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders list of playlists when state is loaded', (tester) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(PlaylistSearchBar), findsOneWidget);
    expect(find.byType(PlaylistCard), findsOneWidget);
    expect(find.text('Test Playlist'), findsOneWidget);
  });

  testWidgets('renders empty state when no playlists', (tester) async {
    when(
      () => mockPlaylistsBloc.state,
    ).thenReturn(const PlaylistsState.loaded(playlists: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('No playlists yet'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets('should call create playlist dialog when add button pressed', (
    tester,
  ) async {
    when(
      () => mockPlaylistsBloc.state,
    ).thenReturn(const PlaylistsState.loaded(playlists: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Create Playlist'), findsWidgets);
  });

  testWidgets('renders error message and retry button when state is error', (
    tester,
  ) async {
    when(
      () => mockPlaylistsBloc.state,
    ).thenReturn(const PlaylistsState.error('Error loading playlists'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Error loading playlists'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    // called(2) because first is in initState, second is on retry tap
    verify(() => mockPlaylistsBloc.add(const LoadPlaylistsEvent())).called(2);
  });

  testWidgets('calls refresh playlists when refresh button pressed', (
    tester,
  ) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.refresh));
    verify(
      () => mockPlaylistsBloc.add(const RefreshPlaylistsEvent()),
    ).called(1);
  });

  testWidgets('calls search playlists when search query changes', (
    tester,
  ) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final Finder searchField = find.byType(TextField);
    await tester.enterText(searchField, 'query');
    await tester.pump();

    verify(
      () => mockPlaylistsBloc.add(const SearchPlaylistsEvent('query')),
    ).called(1);
  });

  testWidgets('calls clear search when clear button pressed', (tester) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
        searchQuery: 'query',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    verify(() => mockPlaylistsBloc.add(const ClearSearchEvent())).called(1);
  });

  testWidgets('calls toggle favorite when favorite button pressed', (
    tester,
  ) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Open more menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap favorite
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    verify(
      () => mockPlaylistsBloc.add(ToggleFavoriteEvent(tPlaylist.id)),
    ).called(1);
  });

  testWidgets('shows delete confirmation and calls delete when confirmed', (
    tester,
  ) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Open more menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap delete in menu
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Verify dialog is shown and tap delete button in dialog
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(
      () => mockPlaylistsBloc.add(DeletePlaylistEvent(tPlaylist.id)),
    ).called(1);
  });

  testWidgets('calls play playlist when play button pressed', (tester) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Open more menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap play
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
  });

  testWidgets('calls edit playlist when edit button pressed', (tester) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Open more menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap edit
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
  });

  testWidgets('calls navigate to details when card is tapped', (tester) async {
    when(() => mockPlaylistsBloc.state).thenReturn(
      PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byType(PlaylistCard));
    await tester.pumpAndSettle();
  });

  testWidgets('shows create dialog from empty state button', (tester) async {
    when(
      () => mockPlaylistsBloc.state,
    ).thenReturn(const PlaylistsState.loaded(playlists: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Create Playlist'));
    await tester.pumpAndSettle();

    expect(find.byType(CreatePlaylistDialog), findsOneWidget);
  });

  testWidgets('triggers side effects in listener', (tester) async {
    whenListen(
      mockPlaylistsBloc,
      Stream.fromIterable([
        const PlaylistsState.error('Listener Error'),
        PlaylistsState.playlistUpdated(
          playlist: tPlaylist,
          playlists: [tPlaylist],
        ),
        PlaylistsState.playlistDeleted(
          playlistId: tPlaylist.id,
          playlists: const [],
        ),
        PlaylistsState.favoriteToggled(
          playlist: tPlaylist,
          playlists: [tPlaylist],
        ),
      ]),
      initialState: const PlaylistsState.initial(),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
  });
}
