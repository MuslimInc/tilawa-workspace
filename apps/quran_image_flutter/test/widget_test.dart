import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image_flutter/main.dart';

void main() {
  testWidgets('Quran image app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranImageApp());

    // Verify that the app builds without errors
    expect(find.byType(QuranImageReader), findsOneWidget);
  });
}
