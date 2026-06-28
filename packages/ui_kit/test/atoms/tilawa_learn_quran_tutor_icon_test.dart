import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaLearnQuranTutorIcon', () {
    testWidgets(
      'renders person and mushaf without overflow at icon well sizes',
      (
        WidgetTester tester,
      ) async {
        const Color accent = Color(0xFF219653);

        for (final double iconSize in <double>[24, 32, 40]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: iconSize + 16,
                    height: iconSize + 16,
                    child: Center(
                      child: TilawaLearnQuranTutorIcon(
                        size: iconSize,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(TilawaLearnQuranTutorIcon), findsOneWidget);
          expect(find.byType(Icon), findsOneWidget);
          expect(find.byType(SvgPicture), findsOneWidget);
        }
      },
    );
  });
}
