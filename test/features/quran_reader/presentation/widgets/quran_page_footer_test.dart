import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_page_footer.dart';

void main() {
  group('QuranPageFooter', () {
    testWidgets('should display hizb number and page number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: QuranPageFooter(hizbNumber: 1, pageNumber: 1)),
        ),
      );

      expect(find.text('Hizb 1'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
