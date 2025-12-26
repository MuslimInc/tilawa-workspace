import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';
import 'package:tilawa/features/playlists/presentation/bloc/playlists_bloc.dart';
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
  });
}
