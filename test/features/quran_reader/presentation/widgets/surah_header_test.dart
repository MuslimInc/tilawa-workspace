import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_header.dart';

void main() {
  group('SurahHeader', () {
    testWidgets('should build successfully for surah 2', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SurahHeader(surahNumber: 2))),
      );

      expect(find.byType(SurahHeader), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should build successfully for surah 1 (Al-Fatiha)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SurahHeader(surahNumber: 1))),
      );

      expect(find.byType(SurahHeader), findsOneWidget);
    });

    testWidgets('should build successfully for surah 9 (At-Tawbah)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SurahHeader(surahNumber: 9))),
      );

      expect(find.byType(SurahHeader), findsOneWidget);
    });

    testWidgets('should render header container', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SurahHeader(surahNumber: 114))),
      );

      // Container should exist
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should handle missing surah image gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SurahHeader(surahNumber: 1))),
      );

      // Should render without crash even if image is missing
      await tester.pump();
      expect(find.byType(SurahHeader), findsOneWidget);
    });
  });
}
