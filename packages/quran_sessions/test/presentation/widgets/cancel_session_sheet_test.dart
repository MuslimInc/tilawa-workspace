import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/widget_pump.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    bool isManualPayment = false,
    Locale? locale,
    TextDirection? textDirection,
  }) async {
    if (locale == null && textDirection == null) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showCancelSessionSheet(
                    context,
                    sessionStartsAt: DateTime.utc(2026, 7, 1, 10),
                    pricingType: SessionPricingType.free,
                    isManualPayment: isManualPayment,
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );
    } else {
      await pumpInApp(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showCancelSessionSheet(
                context,
                sessionStartsAt: DateTime.utc(2026, 7, 1, 10),
                pricingType: SessionPricingType.free,
                isManualPayment: isManualPayment,
              ),
              child: const Text('open'),
            );
          },
        ),
        locale: locale,
        textDirection: textDirection,
        surfaceSize: const Size(800, 1200),
        settle: false,
      );
    }

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('cancel sheet uses kit scaffold with keep as primary', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byType(TilawaBottomSheetScaffold), findsOneWidget);
    expect(find.text('Keep session'), findsOneWidget);
    expect(find.text('Cancel session'), findsOneWidget);
  });

  testWidgets('cancel sheet requires reason before confirming cancel', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Cancel session'));
    await tester.pump();

    expect(find.text('Please enter at least 3 characters.'), findsOneWidget);
  });

  testWidgets(
    'manual-paid cancel sheet shows cancellation policy not payment instructions',
    (tester) async {
      await pumpSheet(tester, isManualPayment: true);

      final l10n = lookupQuranSessionsLocalizations(const Locale('en'));

      expect(
        find.textContaining(l10n.manualPaymentCancellationPolicy),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          l10n.manualPaymentCancellationSupportHint(
            ManualPaymentMarketConfig.egFallback.supportWhatsappNumber,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          ManualPaymentMarketConfig.egFallback.instapayHandle!,
        ),
        findsNothing,
      );
      expect(
        find.textContaining(
          ManualPaymentMarketConfig.egFallback.instapayPaymentLink!,
        ),
        findsNothing,
      );
      expect(
        find.textContaining(
          ManualPaymentMarketConfig.egFallback.recipientMaskedName!,
        ),
        findsNothing,
      );
      expect(
        find.textContaining(l10n.manualPaymentReceiptWhatsappInstruction),
        findsNothing,
      );
      expect(find.textContaining('Free session'), findsNothing);
    },
  );

  testWidgets(
    'manual-paid cancel sheet shows Arabic cancellation policy',
    (tester) async {
      await pumpSheet(
        tester,
        isManualPayment: true,
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      );

      final l10n = lookupQuranSessionsLocalizations(const Locale('ar'));

      expect(
        find.textContaining(l10n.manualPaymentCancellationPolicy),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          l10n.manualPaymentCancellationSupportHint(
            ManualPaymentMarketConfig.egFallback.supportWhatsappNumber,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          ManualPaymentMarketConfig.egFallback.instapayHandle!,
        ),
        findsNothing,
      );
    },
  );
}
