import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/profile_avatar.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('ProfileAvatar', () {
    testWidgets('empty photoUrl stays circular in wide parent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              child: Column(
                children: [
                  ProfileAvatar(size: 72),
                ],
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(TilawaProfileAvatar));
      check(size.width).equals(72);
      check(size.height).equals(72);
    });

    testWidgets('bottom nav size initial fallback stays circular', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: const Scaffold(
            body: Center(
              child: ProfileAvatar(
                displayName: 'Teacher User',
                size: 28,
                fallbackStyle: ProfileAvatarFallbackStyle.initial,
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(TilawaProfileAvatar));
      check(size.width).equals(28);
      check(size.height).equals(28);
      check(find.text('T').evaluate().length).equals(1);
    });
  });
}
