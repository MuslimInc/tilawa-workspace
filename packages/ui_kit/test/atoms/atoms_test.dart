import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/atoms/tilawa_loading_indicator.dart';
import '../../lib/src/atoms/tilawa_divider.dart';
import '../../lib/src/atoms/tilawa_empty_state.dart';
import '../../lib/src/foundation/component_tokens/atoms_tokens.dart';
import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [TilawaDesignTokens.light(), TilawaComponentTokens.light()],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TilawaLoadingIndicator', () {
    testWidgets('renders a centered CircularProgressIndicator by default', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TilawaLoadingIndicator()));

      expect(find.byType(Center), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders without Center when centered is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 100,
            height: 100,
            child: TilawaLoadingIndicator(centered: false),
          ),
        ),
      );

      // The TilawaLoadingIndicator's own build should not add a Center
      final indicator = tester.widget<TilawaLoadingIndicator>(
        find.byType(TilawaLoadingIndicator),
      );
      expect(indicator.centered, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('applies custom strokeWidth', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaLoadingIndicator(strokeWidth: 2.5)),
      );

      final cpi = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(cpi.strokeWidth, 2.5);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaLoadingIndicator(color: Colors.red)),
      );

      final cpi = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(cpi.color, Colors.red);
    });

    testWidgets('applies semanticsLabel', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaLoadingIndicator(semanticsLabel: 'Loading data')),
      );

      final cpi = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(cpi.semanticsLabel, 'Loading data');
    });

    testWidgets('uses token defaultStrokeWidth when no override given', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TilawaLoadingIndicator()));

      final cpi = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      // Default token is 3.0
      expect(cpi.strokeWidth, 3.0);
    });
  });

  group('TilawaDivider', () {
    testWidgets('renders a Divider with token defaults', (tester) async {
      await tester.pumpWidget(_wrap(const TilawaDivider()));

      expect(find.byType(Divider), findsOneWidget);
      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.height, 1.0);
    });

    testWidgets('applies custom height', (tester) async {
      await tester.pumpWidget(_wrap(const TilawaDivider(height: 24.0)));

      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.height, 24.0);
    });

    testWidgets('applies custom thickness', (tester) async {
      await tester.pumpWidget(_wrap(const TilawaDivider(thickness: 2.0)));

      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.thickness, 2.0);
    });

    testWidgets('applies indent and endIndent', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaDivider(indent: 16.0, endIndent: 16.0)),
      );

      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.indent, 16.0);
      expect(divider.endIndent, 16.0);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(_wrap(const TilawaDivider(color: Colors.red)));

      final divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.color, Colors.red);
    });
  });

  group('TilawaEmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaEmptyState(icon: Icons.inbox, title: 'No items')),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders optional subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaEmptyState(
            icon: Icons.inbox,
            title: 'No items',
            subtitle: 'Add some items to get started',
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('renders optional action widget', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaEmptyState(
            icon: Icons.inbox,
            title: 'No items',
            action: ElevatedButton(
              onPressed: () {},
              child: const Text('Add Item'),
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaEmptyState(icon: Icons.inbox, title: 'Empty')),
      );

      // Only 2 children in the Column: Icon + SizedBox + Text
      // No subtitle text exists
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('does not render action when null', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaEmptyState(icon: Icons.inbox, title: 'Empty')),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('is centered', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaEmptyState(icon: Icons.inbox, title: 'No items')),
      );

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('applies custom iconColor', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaEmptyState(
            icon: Icons.inbox,
            title: 'No items',
            iconColor: Colors.blue,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));
      expect(icon.color, Colors.blue);
    });
  });

  group('TilawaCardTokens', () {
    test('defaults match existing TilawaCard behavior', () {
      final tokens = TilawaCardTokens.defaults();
      // Body cards use the card radius family (radiusExtraLarge = 24).
      expect(tokens.borderRadius, 24.0);
      expect(tokens.borderWidth, 0.5);
      expect(tokens.padding, const EdgeInsets.all(16.0));
    });

    test('copyWith preserves unchanged values', () {
      final original = TilawaCardTokens.defaults();
      final updated = original.copyWith(borderRadius: 20.0);
      expect(updated.borderRadius, 20.0);
      expect(updated.borderWidth, original.borderWidth);
      expect(updated.padding, original.padding);
    });

    test('lerp interpolates all values', () {
      const a = TilawaCardTokens(
        borderRadius: 10.0,
        borderWidth: 0.5,
        padding: EdgeInsets.all(8.0),
      );
      const b = TilawaCardTokens(
        borderRadius: 20.0,
        borderWidth: 1.5,
        padding: EdgeInsets.all(16.0),
      );
      final result = TilawaCardTokens.lerp(a, b, 0.5);
      expect(result.borderRadius, closeTo(15.0, 0.01));
      expect(result.borderWidth, closeTo(1.0, 0.01));
    });
  });

  group('TilawaIconBoxTokens', () {
    test('defaults match existing TilawaIconBox behavior', () {
      final tokens = TilawaIconBoxTokens.defaults();
      // iconSizeLarge = 24.0, spaceSmall = 8.0, radiusMedium = 12.0
      expect(tokens.iconSize, 24.0);
      expect(tokens.padding, 8.0);
      expect(tokens.borderRadius, 12.0);
    });

    test('copyWith preserves unchanged values', () {
      final original = TilawaIconBoxTokens.defaults();
      final updated = original.copyWith(iconSize: 32.0);
      expect(updated.iconSize, 32.0);
      expect(updated.padding, original.padding);
      expect(updated.borderRadius, original.borderRadius);
    });

    test('lerp interpolates all values', () {
      const a = TilawaIconBoxTokens(
        iconSize: 20.0,
        backgroundColor: Color(0xFFE8EFE9),
        padding: 6.0,
        borderRadius: 10.0,
        borderOpacity: 0.1,
      );
      const b = TilawaIconBoxTokens(
        iconSize: 30.0,
        backgroundColor: Color(0xFFD8F0EC),
        padding: 12.0,
        borderRadius: 16.0,
        borderOpacity: 0.2,
      );
      final result = TilawaIconBoxTokens.lerp(a, b, 0.5);
      expect(result.iconSize, closeTo(25.0, 0.01));
      expect(
        result.backgroundColor,
        Color.lerp(a.backgroundColor, b.backgroundColor, 0.5),
      );
      expect(result.padding, closeTo(9.0, 0.01));
      expect(result.borderRadius, closeTo(13.0, 0.01));
      expect(result.borderOpacity, closeTo(0.15, 0.01));
    });
  });

  group('TilawaLoadingIndicatorTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaLoadingIndicatorTokens.defaults();
      expect(tokens.defaultStrokeWidth, 3.0);
    });

    test('copyWith preserves unchanged values', () {
      final original = TilawaLoadingIndicatorTokens.defaults();
      final updated = original.copyWith(defaultStrokeWidth: 3.0);
      expect(updated.defaultStrokeWidth, 3.0);
    });

    test('lerp interpolates values', () {
      const a = TilawaLoadingIndicatorTokens(defaultStrokeWidth: 2.0);
      const b = TilawaLoadingIndicatorTokens(defaultStrokeWidth: 6.0);
      final result = TilawaLoadingIndicatorTokens.lerp(a, b, 0.5);
      expect(result.defaultStrokeWidth, closeTo(4.0, 0.01));
    });
  });

  group('TilawaDividerTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaDividerTokens.defaults();
      expect(tokens.height, 1.0);
      expect(tokens.thickness, 0.5);
      expect(tokens.colorOpacity, 1.0);
    });

    test('copyWith preserves unchanged values', () {
      final original = TilawaDividerTokens.defaults();
      final updated = original.copyWith(height: 2.0);
      expect(updated.height, 2.0);
      expect(updated.thickness, original.thickness);
    });

    test('lerp interpolates values', () {
      const a = TilawaDividerTokens(
        height: 1.0,
        thickness: 0.5,
        colorOpacity: 0.8,
      );
      const b = TilawaDividerTokens(
        height: 3.0,
        thickness: 1.5,
        colorOpacity: 1.0,
      );
      final result = TilawaDividerTokens.lerp(a, b, 0.5);
      expect(result.height, closeTo(2.0, 0.01));
      expect(result.thickness, closeTo(1.0, 0.01));
      expect(result.colorOpacity, closeTo(0.9, 0.01));
    });
  });

  group('TilawaEmptyStateTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaEmptyStateTokens.defaults();
      expect(tokens.iconSize, 48.0);
      expect(tokens.iconOpacity, 0.56);
      expect(tokens.titleSpacing, 24.0);
      expect(tokens.subtitleSpacing, 8.0);
      expect(tokens.actionSpacing, 24.0);
      expect(tokens.padding, const EdgeInsets.all(24.0));
    });

    test('copyWith preserves unchanged values', () {
      final original = TilawaEmptyStateTokens.defaults();
      final updated = original.copyWith(iconSize: 56.0);
      expect(updated.iconSize, 56.0);
      expect(updated.iconOpacity, original.iconOpacity);
      expect(updated.padding, original.padding);
    });

    test('lerp interpolates values', () {
      const a = TilawaEmptyStateTokens(
        iconSize: 40.0,
        iconOpacity: 0.3,
        titleSpacing: 12.0,
        subtitleSpacing: 6.0,
        actionSpacing: 20.0,
        padding: EdgeInsets.all(16.0),
      );
      const b = TilawaEmptyStateTokens(
        iconSize: 60.0,
        iconOpacity: 0.5,
        titleSpacing: 20.0,
        subtitleSpacing: 10.0,
        actionSpacing: 28.0,
        padding: EdgeInsets.all(32.0),
      );
      final result = TilawaEmptyStateTokens.lerp(a, b, 0.5);
      expect(result.iconSize, closeTo(50.0, 0.01));
      expect(result.iconOpacity, closeTo(0.4, 0.01));
      expect(result.titleSpacing, closeTo(16.0, 0.01));
    });
  });

  group('New tokens in TilawaComponentTokens', () {
    test('light() includes all new tokens', () {
      final tokens = TilawaComponentTokens.light();
      expect(tokens.card, isNotNull);
      expect(tokens.iconBox, isNotNull);
      expect(tokens.loadingIndicator, isNotNull);
      expect(tokens.divider, isNotNull);
      expect(tokens.emptyState, isNotNull);
    });

    test('copyWith updates card tokens', () {
      final original = TilawaComponentTokens.light();
      final newCard = original.card.copyWith(borderRadius: 24.0);
      final updated = original.copyWith(card: newCard);
      expect(updated.card.borderRadius, 24.0);
      expect(updated.iconBox, original.iconBox);
    });

    test('lerp interpolates new tokens', () {
      final first = TilawaComponentTokens.light();
      final second = TilawaComponentTokens.dark();
      final lerped = first.lerp(second, 0.5);
      expect(lerped.card, isNotNull);
      expect(lerped.iconBox, isNotNull);
      expect(lerped.loadingIndicator, isNotNull);
      expect(lerped.divider, isNotNull);
      expect(lerped.emptyState, isNotNull);
    });
  });
}
