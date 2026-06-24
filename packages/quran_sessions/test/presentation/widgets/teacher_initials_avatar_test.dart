import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_initials_avatar.dart';

Future<void> _pumpAvatar(
  WidgetTester tester, {
  required String displayName,
  String? avatarUrl,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TeacherInitialsAvatar(
          displayName: displayName,
          radius: 24,
          avatarUrl: avatarUrl,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('empty displayName renders person icon fallback', (tester) async {
    await _pumpAvatar(tester, displayName: '');

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('؟'), findsNothing);
  });

  testWidgets('single-word name uses its first character', (tester) async {
    await _pumpAvatar(tester, displayName: 'Ahmed');

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('two-word name uses the first character of each word', (
    tester,
  ) async {
    await _pumpAvatar(tester, displayName: 'Sheikh Ahmed');

    expect(find.text('SA'), findsOneWidget);
  });

  testWidgets('Arabic honorific prefix is skipped for initials', (
    tester,
  ) async {
    await _pumpAvatar(tester, displayName: 'الشيخ أحمد محمد');

    expect(find.text('أم'), findsOneWidget);
  });

  testWidgets('single meaningful word after honorific uses its first char', (
    tester,
  ) async {
    await _pumpAvatar(tester, displayName: 'الشيخ أحمد');

    expect(find.text('أ'), findsOneWidget);
  });

  testWidgets('same name is rendered with a stable background colour', (
    tester,
  ) async {
    await _pumpAvatar(tester, displayName: 'Sheikh Ahmed');
    final first = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    await _pumpAvatar(tester, displayName: 'Sheikh Ahmed');
    final second = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(first.backgroundColor, second.backgroundColor);
  });
}
