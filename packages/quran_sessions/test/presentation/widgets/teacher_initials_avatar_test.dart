import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_initials_avatar.dart';

void main() {
  testWidgets('empty displayName renders person icon fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherInitialsAvatar(
            displayName: '',
            radius: 24,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('؟'), findsNothing);
  });
}
