import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_hero.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

ThemeData _testTheme() =>
    AppTheme.getLightTheme(primaryColor: const Color(0xFF2E7D6F));

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: _testTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('QuranPlayerHeroArtwork', () {
    testWidgets('renders placeholder when artUri is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QuranPlayerHeroArtwork(
            audioId: '1',
            artUri: null,
            borderRadius: BorderRadius.circular(8),
            size: const Size(48, 48),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(QuranPlayerHeroArtwork), findsOneWidget);
      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('uses expanded artwork semantics when requested', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          QuranPlayerHeroArtwork(
            audioId: '2',
            artUri: null,
            borderRadius: BorderRadius.circular(8),
            size: const Size(64, 64),
            semanticDestination: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(QuranPlayerHeroArtwork), findsOneWidget);
    });
  });

  group('QuranPlayerHeroMetadata', () {
    testWidgets('renders start-aligned metadata', (tester) async {
      final ThemeData theme = _testTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: QuranPlayerHeroMetadata(
              audioId: '3',
              title: 'Al-Fatiha',
              subtitle: 'Reciter',
              titleStyle: theme.textTheme.titleMedium!,
              subtitleStyle: theme.textTheme.bodySmall!,
            ),
          ),
        ),
      );

      expect(find.text('Al-Fatiha'), findsOneWidget);
      expect(find.text('Reciter'), findsOneWidget);
    });

    testWidgets('renders center-aligned metadata with destination semantics', (
      tester,
    ) async {
      final ThemeData theme = _testTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: QuranPlayerHeroMetadata(
              audioId: '4',
              title: 'Title',
              subtitle: 'Artist',
              titleStyle: theme.textTheme.titleMedium!,
              subtitleStyle: theme.textTheme.bodySmall!,
              centerAlign: true,
              semanticDestination: true,
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
    });
  });
}
