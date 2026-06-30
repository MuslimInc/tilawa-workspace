import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/widget_pump.dart';

Future<void> pumpOverrideTypeChipRow(
  WidgetTester tester, {
  required Locale locale,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await pumpInApp(
    tester,
    Builder(
      builder: (context) {
        final l10n = QuranSessionsLocalizations.of(context);
        final tokens = Theme.of(context).tokens;
        final scheme = Theme.of(context).colorScheme;

        return Padding(
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
        );
      },
    ),
    locale: locale,
    textDirection: textDirection,
    surfaceSize: const Size(360, 120),
  );
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
