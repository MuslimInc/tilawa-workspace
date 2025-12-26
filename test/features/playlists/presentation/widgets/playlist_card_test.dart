import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';
import 'package:tilawa/features/playlists/presentation/widgets/playlist_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  late Playlist testPlaylist;

  setUp(() {
    testPlaylist = Playlist(
      id: '1',
      name: 'Test Playlist',
      description: 'Test Description',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [
        PlaylistItem(
          id: '1',
          title: 'Track 1',
          artist: 'Artist 1',
          url: 'url1',
          duration: const Duration(minutes: 2, seconds: 30),
          addedAt: DateTime.now(),
        ),
        PlaylistItem(
          id: '2',
          title: 'Track 2',
          artist: 'Artist 2',
          url: 'url2',
          duration: const Duration(minutes: 3, seconds: 30),
          addedAt: DateTime.now(),
        ),
      ],
    );
  });

  Widget createWidget({
    required Playlist playlist,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onToggleFavorite,
    VoidCallback? onPlay,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PlaylistCard(
          playlist: playlist,
          onTap: onTap ?? () {},
          onEdit: onEdit ?? () {},
          onDelete: onDelete ?? () {},
          onToggleFavorite: onToggleFavorite ?? () {},
          onPlay: onPlay ?? () {},
        ),
      ),
    );
  }

  group('PlaylistCard', () {
    testWidgets('renders playlist information correctly', (tester) async {
      await tester.pumpWidget(createWidget(playlist: testPlaylist));
      await tester.pumpAndSettle();

      expect(find.text('Test Playlist'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      // Assuming English locale, might need to adjust based on l10n
      // Check if we can find text containing "2" and "items" if exact match fails,
      // but exact match is better if we control l10n.
      // app_localizations.dart usually has defaults or needs one loaded.
      // Since we use supportedLocales, it should load English by default.

      // We will look for substrings if exact l10n strings are not known perfectly,
      // but based on code: '${playlist.itemCount} ${l10n.playlistItemCount}'
      // and '2 items' is likely string for English.
      expect(find.text('2 Items'), findsOneWidget);
      expect(find.text('06:00'), findsOneWidget); // 2:30 + 3:30 = 6:00
      expect(find.text('Public'), findsNothing);
    });

    testWidgets('shows public tag when playlist is public', (tester) async {
      final Playlist publicPlaylist = testPlaylist.copyWith(isPublic: true);
      await tester.pumpWidget(createWidget(playlist: publicPlaylist));
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        createWidget(playlist: testPlaylist, onTap: () => tapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Playlist'));
      expect(tapped, isTrue);
    });

    testWidgets('shows menu options when menu button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(playlist: testPlaylist));
      await tester.pumpAndSettle();

      final Finder menuButton = find.byType(PopupMenuButton<String>);
      expect(menuButton, findsOneWidget);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.text('Play Playlist'), findsOneWidget);
      expect(find.text('Edit Playlist'), findsOneWidget);
      expect(find.text('Add to Favorites'), findsOneWidget);
      expect(find.text('Delete Playlist'), findsOneWidget);
    });

    testWidgets('calls callbacks when menu items are selected', (tester) async {
      var played = false;
      var edited = false;
      var favorited = false;
      var deleted = false;

      await tester.pumpWidget(
        createWidget(
          playlist: testPlaylist,
          onPlay: () => played = true,
          onEdit: () => edited = true,
          onToggleFavorite: () => favorited = true,
          onDelete: () => deleted = true,
        ),
      );
      await tester.pumpAndSettle();

      // Test Play
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Playlist'));
      await tester.pumpAndSettle();
      expect(played, isTrue);

      // Test Edit
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Playlist'));
      await tester.pumpAndSettle();
      expect(edited, isTrue);

      // Test Favorite
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Favorites'));
      await tester.pumpAndSettle();
      expect(favorited, isTrue);

      // Test Delete
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Playlist'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('shows correct favorite status', (tester) async {
      // Not favorite
      await tester.pumpWidget(createWidget(playlist: testPlaylist));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Add to Favorites'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Close menu by tapping barrier or just pump new widget
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      // Favorite
      final Playlist favoritePlaylist = testPlaylist.copyWith(isFavorite: true);
      await tester.pumpWidget(createWidget(playlist: favoritePlaylist));
      await tester.pumpAndSettle();

      // Need to find the NEW menu button in the new widget tree
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('formats duration correctly when greater than 1 hour', (
      tester,
    ) async {
      final Playlist longPlaylist = testPlaylist.copyWith(
        items: [
          PlaylistItem(
            id: '1',
            title: 'Long Track',
            artist: 'Artist',
            url: 'url',
            duration: const Duration(hours: 1, minutes: 30, seconds: 5),
            addedAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(createWidget(playlist: longPlaylist));
      await tester.pumpAndSettle();

      // 01:30:05
      expect(find.text('01:30:05'), findsOneWidget);
    });
  });
}
