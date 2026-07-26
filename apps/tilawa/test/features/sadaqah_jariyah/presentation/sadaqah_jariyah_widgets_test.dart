import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/dedication.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/enums/dedication_status.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/widgets/sadaqah_jariyah_dedication_card.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/widgets/sadaqah_jariyah_letter_avatar.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/widgets/sadaqah_jariyah_list.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getLightTheme(primaryColor: const Color(0xFFE05A33)),
      home: Scaffold(body: child),
    );
  }

  testWidgets('letter avatar shows first grapheme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(const SadaqahJariyahLetterAvatar(name: 'Ahmed')),
    );
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('list renders photo and name without extra metadata', (
    WidgetTester tester,
  ) async {
    final List<Dedication> dedications = <Dedication>[
      const Dedication(
        id: 'founding',
        displayName: 'Ahmed Mohamed Tony',
        slug: 'ahmed-mohamed-tony',
        status: DedicationStatus.published,
        isFounding: true,
        isFeatured: false,
        sortOrder: 0,
        note: 'Should not show',
      ),
      const Dedication(
        id: 'other',
        displayName: 'Other Person',
        slug: 'other-person',
        status: DedicationStatus.published,
        isFounding: false,
        isFeatured: false,
        sortOrder: 1,
        note: 'Remembered with love',
      ),
    ];

    await tester.pumpWidget(
      wrap(
        SadaqahJariyahList(
          dedications: dedications,
          photoUrls: const <String, String?>{},
        ),
      ),
    );

    expect(find.byType(SadaqahJariyahDedicationCard), findsNWidgets(2));
    expect(find.byType(SadaqahJariyahLetterAvatar), findsOneWidget);
    expect(find.text('Founding'), findsNothing);
    expect(find.text('Should not show'), findsNothing);
    expect(find.text('Remembered with love'), findsNothing);

    final Finder founding = find.text('Ahmed Mohamed Tony');
    final Finder other = find.text('Other Person');
    expect(founding, findsOneWidget);
    expect(other, findsOneWidget);
    expect(
      tester.getTopLeft(founding).dy < tester.getTopLeft(other).dy,
      isTrue,
    );
  });
}
