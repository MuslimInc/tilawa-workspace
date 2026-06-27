import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/shell/application/shell_tab_reselect.dart';

void main() {
  group('ShellTabReselect', () {
    testWidgets('scrolls to top when list is scrolled down', (tester) async {
      final controller = ScrollController();
      var refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 40,
              itemBuilder: (_, index) =>
                  SizedBox(height: 48, child: Text('$index')),
            ),
          ),
        ),
      );
      await tester.pump();

      controller.jumpTo(240);
      await tester.pump();

      final future = ShellTabReselect.scrollToTopOrRefresh(
        scrollController: controller,
        refresh: () async {
          refreshed = true;
        },
      );
      await tester.pumpAndSettle();
      await future;

      expect(controller.offset, 0);
      expect(refreshed, isFalse);

      controller.dispose();
    });

    testWidgets('refreshes when already at top', (tester) async {
      final controller = ScrollController();
      var refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 400, child: Text('top'))],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await ShellTabReselect.scrollToTopOrRefresh(
        scrollController: controller,
        refresh: () async {
          refreshed = true;
        },
      );

      expect(refreshed, isTrue);
      controller.dispose();
    });
  });
}
