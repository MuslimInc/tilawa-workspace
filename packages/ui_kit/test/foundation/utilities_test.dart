import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/color_scheme_ext.dart';
import '../../lib/src/foundation/shell_padding.dart';
import '../../lib/src/foundation/text_theme_ext.dart';
import '../../lib/src/organisms/tilawa_adaptive_shell.dart';

void main() {
  group('TilawaShellPadding', () {
    testWidgets('of() returns padding from context', (
      WidgetTester tester,
    ) async {
      const double padding = 16.0;

      await tester.pumpWidget(
        MaterialApp(
          home: TilawaShellPadding(
            padding: padding,
            child: Builder(
              builder: (context) {
                final retrievedPadding = TilawaShellPadding.of(context);
                expect(retrievedPadding, padding);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('of() returns 0 when not in TilawaShellPadding tree', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = TilawaShellPadding.of(context);
              expect(padding, 0.0);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('updateShouldNotify returns true when padding changes', (
      WidgetTester tester,
    ) async {
      const double initialPadding = 16.0;
      const double newPadding = 24.0;

      final key = GlobalKey<_TestShellPaddingState>();

      await tester.pumpWidget(
        MaterialApp(
          home: _TestShellPaddingWidget(key: key, padding: initialPadding),
        ),
      );

      expect(find.text('Padding: $initialPadding'), findsOneWidget);

      key.currentState!.updatePadding(newPadding);
      await tester.pumpWidget(
        MaterialApp(
          home: _TestShellPaddingWidget(key: key, padding: newPadding),
        ),
      );

      expect(find.text('Padding: $newPadding'), findsOneWidget);
    });

    testWidgets('nested TilawaShellPadding uses closest ancestor', (
      WidgetTester tester,
    ) async {
      const double outerPadding = 16.0;
      const double innerPadding = 24.0;

      await tester.pumpWidget(
        MaterialApp(
          home: TilawaShellPadding(
            padding: outerPadding,
            child: Builder(
              builder: (outerContext) {
                expect(TilawaShellPadding.of(outerContext), outerPadding);
                return TilawaShellPadding(
                  padding: innerPadding,
                  child: Builder(
                    builder: (innerContext) {
                      expect(TilawaShellPadding.of(innerContext), innerPadding);
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  });

  group('TextThemeExtension', () {
    testWidgets('textTheme returns Theme.of().textTheme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 16)),
          ),
          home: Builder(
            builder: (context) {
              final textTheme = context.textTheme;
              expect(textTheme.bodyLarge?.fontSize, 16);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('textTheme works in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 17)),
          ),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              final textTheme = context.textTheme;
              expect(textTheme.bodyLarge?.fontSize, 17);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('ColorSchemeExtension', () {
    testWidgets('colorScheme returns Theme.of().colorScheme', (
      WidgetTester tester,
    ) async {
      const primaryColor = Color(0xFF6200EA);
      const secondaryColor = Color(0xFF03DAC6);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              secondary: secondaryColor,
            ),
          ),
          home: Builder(
            builder: (context) {
              final colorScheme = context.colorScheme;
              expect(colorScheme.primary, primaryColor);
              expect(colorScheme.secondary, secondaryColor);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('primaryColor returns colorScheme.primary', (
      WidgetTester tester,
    ) async {
      const primaryColor = Color(0xFF6200EA);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          home: Builder(
            builder: (context) {
              expect(context.primaryColor, primaryColor);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('secondaryColor returns colorScheme.secondary', (
      WidgetTester tester,
    ) async {
      const secondaryColor = Color(0xFF03DAC6);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(secondary: secondaryColor),
          ),
          home: Builder(
            builder: (context) {
              expect(context.secondaryColor, secondaryColor);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('extensions work in dark theme', (WidgetTester tester) async {
      const darkPrimary = Color(0xFFBB86FC);
      const darkSecondary = Color(0xFF03DAC6);

      await tester.pumpWidget(
        MaterialApp(
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: darkPrimary,
              secondary: darkSecondary,
            ),
          ),
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              expect(context.primaryColor, darkPrimary);
              expect(context.secondaryColor, darkSecondary);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('TilawaNavDestination', () {
    test('creates instance with all parameters', () {
      const destination = TilawaNavDestination(
        label: 'Home',
        icon: Icons.home,
        activeIcon: Icons.home_filled,
      );

      expect(destination.label, 'Home');
      expect(destination.icon, Icons.home);
      expect(destination.activeIcon, Icons.home_filled);
      expect(destination.iconBuilder, isNull);
    });

    test('creates instance with icon builder', () {
      const destination = TilawaNavDestination(
        label: 'Custom',
        icon: Icons.star,
        iconBuilder: _customIconBuilder,
      );

      expect(destination.label, 'Custom');
      expect(destination.icon, Icons.star);
      expect(destination.iconBuilder, _customIconBuilder);
    });

    test('activeIcon defaults to null', () {
      const destination = TilawaNavDestination(
        label: 'Test',
        icon: Icons.settings,
      );

      expect(destination.activeIcon, isNull);
    });

    test('multiple instances maintain separate state', () {
      const dest1 = TilawaNavDestination(label: 'Home', icon: Icons.home);
      const dest2 = TilawaNavDestination(
        label: 'Settings',
        icon: Icons.settings,
      );

      expect(dest1.label, 'Home');
      expect(dest2.label, 'Settings');
      expect(dest1.icon, Icons.home);
      expect(dest2.icon, Icons.settings);
    });

    test('supports equality comparison', () {
      const dest1 = TilawaNavDestination(label: 'Home', icon: Icons.home);
      const dest2 = TilawaNavDestination(label: 'Home', icon: Icons.home);

      // Both are const, so they should be the same instance
      expect(identical(dest1, dest2), isTrue);
    });

    test('can be used in collections', () {
      const destinations = [
        TilawaNavDestination(label: 'Home', icon: Icons.home),
        TilawaNavDestination(label: 'Search', icon: Icons.search),
        TilawaNavDestination(label: 'Settings', icon: Icons.settings),
      ];

      expect(destinations.length, 3);
      expect(destinations[0].label, 'Home');
      expect(destinations[1].label, 'Search');
      expect(destinations[2].label, 'Settings');
    });
  });
}

// Mock icon builder for testing
Widget _customIconBuilder(
  BuildContext context, {
  required bool isSelected,
  required Color color,
}) {
  return Icon(
    isSelected ? Icons.star : Icons.star_outline,
    color: isSelected ? Colors.amber : color,
  );
}

// Helper widget for testing TilawaShellPadding updates
class _TestShellPaddingWidget extends StatefulWidget {
  const _TestShellPaddingWidget({required Key key, required this.padding})
    : super(key: key);

  final double padding;

  @override
  State<_TestShellPaddingWidget> createState() => _TestShellPaddingState();
}

class _TestShellPaddingState extends State<_TestShellPaddingWidget> {
  late double _padding;

  @override
  void initState() {
    super.initState();
    _padding = widget.padding;
  }

  void updatePadding(double newPadding) {
    setState(() {
      _padding = newPadding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TilawaShellPadding(
      padding: _padding,
      child: Builder(
        builder: (context) {
          final padding = TilawaShellPadding.of(context);
          return Text('Padding: $padding');
        },
      ),
    );
  }
}
