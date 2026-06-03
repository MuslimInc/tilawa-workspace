import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_expanded_route_transition.dart';

void main() {
  group('QuranPlayerExpandedRouteTransition', () {
    testWidgets('reverse hides opaque surface fill', (tester) async {
      final AnimationController controller = AnimationController(
        vsync: tester,
        duration: QuranPlayerExpandedRouteTransition.reverseTransitionDuration,
        reverseDuration:
            QuranPlayerExpandedRouteTransition.reverseTransitionDuration,
        value: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: QuranPlayerExpandedRouteTransition(
              animation: controller,
              child: const ColoredBox(color: Colors.red),
            ),
          ),
        ),
      );

      controller.reverse();
      await tester.pump();

      expect(find.byType(Opacity), findsWidgets);
      expect(find.byType(Transform), findsWidgets);

      controller.dispose();
    });
  });
}
