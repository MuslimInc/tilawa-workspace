import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/tilawa_ui_kit.dart';

void main() {
  testWidgets('deprecated typedefs from tilawa_ui_kit still resolve', (
    WidgetTester tester,
  ) async {
    // ignore: deprecated_member_use_from_same_package
    final LanguageSwitcher languageSwitcher = LanguageSwitcher(
      currentLanguage: 'en',
      onLanguageChanged: (_) {},
      languages: const ['en', 'ar'],
      getLanguageName: (c) => c == 'en' ? 'English' : 'Arabic',
    );
    expect(languageSwitcher, isA<TilawaLanguageSwitcher>());

    // ignore: deprecated_member_use_from_same_package
    const SelectionPill selectionPill = SelectionPill(
      label: 'x',
      selected: false,
    );
    expect(selectionPill, isA<TilawaSelectionPill>());

    // ignore: deprecated_member_use_from_same_package
    const MetadataChip metadataChip = MetadataChip(label: 'y');
    expect(metadataChip, isA<TilawaMetadataChip>());

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          extensions: [
            TilawaDesignTokens.light(),
            TilawaComponentTokens.light(),
          ],
        ),
        home: Scaffold(
          body: Center(
            child: languageSwitcher,
          ),
        ),
      ),
    );

    final englishInk = find.ancestor(
      of: find.text('English'),
      matching: find.byType(InkWell),
    );
    final sem = tester.getSemantics(englishInk.first);
    expect(sem.flagsCollection.isButton, isTrue);
    expect(sem.flagsCollection.isSelected, Tristate.isTrue);
    expect(sem.label, isNotEmpty);
  });
}
