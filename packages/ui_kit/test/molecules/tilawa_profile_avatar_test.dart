import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaProfileAvatar', () {
    testWidgets('empty photoUrl renders fixed circular ClipOval fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: const Scaffold(
            body: Center(
              child: TilawaProfileAvatar(
                size: 72,
              ),
            ),
          ),
        ),
      );

      check(find.byType(ClipOval).evaluate().length).equals(1);

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(TilawaProfileAvatar),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      check(sizedBox.width).equals(72);
      check(sizedBox.height).equals(72);
      check(find.byType(Icon).evaluate().length).equals(1);
    });

    testWidgets('initial fallback uses displayName without raw T placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: const Scaffold(
            body: Center(
              child: TilawaProfileAvatar(
                size: 28,
                displayName: 'Ahmad',
                fallbackStyle: TilawaProfileAvatarFallbackStyle.initial,
              ),
            ),
          ),
        ),
      );

      check(find.text('A').evaluate().length).equals(1);
      check(find.text('T').evaluate().isEmpty).isTrue();
    });

    testWidgets(
      'empty displayName with initial style falls back to person icon',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ),
            home: const Scaffold(
              body: Center(
                child: TilawaProfileAvatar(
                  size: 28,
                  displayName: '',
                  fallbackStyle: TilawaProfileAvatarFallbackStyle.initial,
                ),
              ),
            ),
          ),
        );

        check(find.text('T').evaluate().isEmpty).isTrue();
        check(find.byType(Icon).evaluate().length).equals(1);
      },
    );

    testWidgets('photoUrl uses circular ClipOval wrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: Scaffold(
            body: Center(
              child: TilawaProfileAvatar(
                size: 48,
                imageUrl: 'https://example.test/avatar.jpg',
                imageBuilder:
                    (context, {required imageUrl, required fallback}) {
                      return ColoredBox(
                        color: Colors.blue,
                        child: fallback,
                      );
                    },
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(TilawaProfileAvatar));
      check(size.width).equals(48);
      check(size.height).equals(48);
      check(find.byType(ClipOval).evaluate().length).equals(1);
    });
  });
}
