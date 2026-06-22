import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Future<void> pumpOverrideTypeChipRow(
  WidgetTester tester, {
  required Locale locale,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(360, 120);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: locale,
      localizationsDelegates: const [
        ...QuranSessionsLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: Directionality(
        textDirection: textDirection,
        child: Builder(
          builder: (context) {
            final l10n = QuranSessionsLocalizations.of(context);
            final tokens = Theme.of(context).tokens;
            final scheme = Theme.of(context).colorScheme;

            return Scaffold(
              body: Padding(
                padding: EdgeInsets.all(tokens.spaceLarge),
                child: Row(
                  children: [
                    Expanded(
                      child: TilawaChip(
                        label: l10n.availabilityOverrideUnavailable,
                        onTap: () {},
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        borderColor: scheme.primary,
                      ),
                    ),
                    SizedBox(width: tokens.spaceSmall),
                    Expanded(
                      child: TilawaChip(
                        label: l10n.availabilityOverrideCustom,
                        onTap: () {},
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.onSurfaceVariant,
                        borderColor: scheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Availability override type chips', () {
    testWidgets('english equal-width row does not overflow', (tester) async {
      await pumpOverrideTypeChipRow(tester, locale: const Locale('en'));

      expect(tester.takeException(), isNull);
      expect(find.text('Unavailable (day off)'), findsOneWidget);
      expect(find.text('Custom hours'), findsOneWidget);
    });

    testWidgets('arabic equal-width row does not overflow', (tester) async {
      await pumpOverrideTypeChipRow(
        tester,
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('غير متاح (إجازة)'), findsOneWidget);
      expect(find.text('ساعات مخصّصة'), findsOneWidget);
    });

    testWidgets('english type chip row golden', (tester) async {
      await pumpOverrideTypeChipRow(tester, locale: const Locale('en'));

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/availability_override_type_chips_en.png',
        ),
      );
    });
  });
}
