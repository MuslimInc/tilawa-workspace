import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _app(Widget child) {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(colorScheme: colorScheme),
      ],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('TilawaCompactListRow stays within compact height budget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 328,
          child: TilawaCompactListRow(
            leading: const Icon(Icons.schedule),
            title: '9:00 AM',
            subtitle: 'Available',
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final rowBox = tester.getRect(find.byType(TilawaCompactListRow));
    final tokens = Theme.of(
      tester.element(find.byType(TilawaCompactListRow)),
    ).tokens;

    expect(
      rowBox.height,
      lessThanOrEqualTo(tokens.minInteractiveDimension + 1),
    );
  });

  testWidgets('TilawaCompactListRow renders inset divider with top spacing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 328,
          child: TilawaCompactListRow(
            leading: const Icon(Icons.schedule),
            title: '9:00 AM',
            subtitle: 'Available',
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {},
            ),
            showDivider: true,
          ),
        ),
      ),
    );

    expect(find.byType(TilawaDivider), findsOneWidget);
  });
}
