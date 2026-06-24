import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/atoms/tilawa_dropdown_field.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_interactive_surface.dart';

const _items = [
  TilawaDropdownItem(value: 'eg', label: 'Egypt', icon: Icons.public),
  TilawaDropdownItem(value: 'sa', label: 'Saudi Arabia'),
];

Widget _wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('TilawaDropdownField', () {
    testWidgets('shows the hint when no value is selected', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Pick a country'), findsOneWidget);
    });

    testWidgets('shows the selected label as the field value', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: 'eg',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Egypt'), findsOneWidget);
    });

    testWidgets('opens the menu and reports the chosen value', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            onChanged: (v) => chosen = v,
          ),
        ),
      );

      await tester.tap(find.byType(TilawaInteractiveSurface));
      await tester.pumpAndSettle();
      // The option appears in the menu overlay.
      await tester.tap(find.text('Saudi Arabia').last);
      await tester.pumpAndSettle();

      expect(chosen, 'sa');
    });

    testWidgets('does not open or report when disabled', (tester) async {
      var changed = false;
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            enabled: false,
            onChanged: (_) => changed = true,
          ),
        ),
      );

      await tester.tap(find.byType(TilawaInteractiveSurface));
      await tester.pumpAndSettle();

      // No menu item rendered → menu never opened.
      expect(find.text('Saudi Arabia'), findsNothing);
      expect(changed, isFalse);
    });

    testWidgets('treats a null onChanged as disabled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            onChanged: null,
          ),
        ),
      );

      await tester.tap(find.byType(TilawaInteractiveSurface));
      await tester.pumpAndSettle();
      expect(find.text('Saudi Arabia'), findsNothing);
    });

    testWidgets('renders the error state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            errorText: 'Required field',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('field border radius comes from the chrome radius token', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: 'eg',
            onChanged: (_) {},
          ),
        ),
      );

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      final border = decorator.decoration.border! as OutlineInputBorder;
      final expected = TilawaDesignTokens.light().resolveRadius(
        family: TilawaRadiusFamily.chrome,
      );
      expect(border.borderRadius, BorderRadius.circular(expected));
    });

    testWidgets('renders under RTL without overflow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: 'sa',
            prefixIcon: Icons.public_outlined,
            onChanged: (_) {},
          ),
          direction: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Saudi Arabia'), findsOneWidget);
    });

    testWidgets('closed field uses white surface fill and meets 48dp height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: 'eg',
            onChanged: (_) {},
          ),
        ),
      );

      final ThemeData theme = Theme.of(
        tester.element(find.byType(TilawaDropdownField<String>)),
      );
      final InputDecorator decorator = tester.widget(
        find.byType(InputDecorator),
      );
      expect(decorator.decoration.filled, isTrue);
      expect(decorator.decoration.fillColor, theme.colorScheme.surface);

      final Size fieldSize = tester.getSize(find.byType(InputDecorator));
      expect(
        fieldSize.height,
        greaterThanOrEqualTo(kTilawaMinInteractiveDimension),
      );
    });

    testWidgets('menu opens below field with bottomStart alignment', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            onChanged: (_) {},
          ),
        ),
      );

      final MenuAnchor anchor = tester.widget(find.byType(MenuAnchor));
      final tokens = TilawaDesignTokens.light();
      expect(
        anchor.style?.alignment,
        AlignmentDirectional.bottomStart,
      );
      expect(anchor.crossAxisUnconstrained, isFalse);
      expect(anchor.style?.elevation?.resolve({}), 0);
      expect(anchor.alignmentOffset, Offset(0, tokens.dropdownMenuGap));
    });

    testWidgets('tapping the prefix icon opens the menu', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            prefixIcon: Icons.public_outlined,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.public_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Egypt').last, findsOneWidget);
    });

    testWidgets('open menu matches the field width', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            onChanged: (_) {},
          ),
        ),
      );

      final Size fieldSize = tester.getSize(find.byType(InputDecorator));

      await tester.tap(find.byType(TilawaInteractiveSurface));
      await tester.pumpAndSettle();

      final Size menuSize = tester.getSize(find.byType(Material).last);
      expect(menuSize.width, fieldSize.width);
    });

    testWidgets('popup menu items are at least 48dp tall', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaDropdownField<String>(
            items: _items,
            value: null,
            hintText: 'Pick a country',
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(TilawaInteractiveSurface));
      await tester.pumpAndSettle();

      final Size itemSize = tester.getSize(
        find.ancestor(
          of: find.text('Egypt').last,
          matching: find.byType(MenuItemButton),
        ),
      );
      expect(itemSize.height, kTilawaMinInteractiveDimension);
    });
  });
}
