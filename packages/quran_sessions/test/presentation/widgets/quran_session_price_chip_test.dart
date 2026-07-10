import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  const paidQuote = SessionPricingQuote(
    pricingType: SessionPricingType.fixedPerSession,
    amount: 100,
    currencyCode: 'EGP',
    paymentRequired: true,
    paymentProviderAvailable: false,
    bookingEnabled: true,
    quranSessionsEnabled: true,
    effectivePricingSource: EffectivePricingSource.marketConfig,
    blockReason: BookingBlockReason.paymentProviderUnavailable,
    countryCode: 'EG',
    cityId: 'cairo',
  );

  const freeQuote = SessionPricingQuote(
    pricingType: SessionPricingType.free,
    amount: 0,
    currencyCode: 'USD',
    paymentRequired: false,
    paymentProviderAvailable: false,
    bookingEnabled: true,
    quranSessionsEnabled: true,
    effectivePricingSource: EffectivePricingSource.teacherOverride,
    blockReason: BookingBlockReason.none,
  );

  testWidgets('renders nothing when pricing is unresolved — never "Free"', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      QuranSessionPriceChip(
        teacher: makeTeacher(
          // The stale entity claims free (legacy DTO default); the chip must
          // not trust it without a resolved market quote.
          pricingType: SessionPricingType.free,
          price: null,
        ),
      ),
    );

    expect(find.byType(TilawaChip), findsNothing);
    expect(find.text('Free'), findsNothing);
  });

  testWidgets('paid quote shows the amount and never the free label', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      QuranSessionPriceChip(
        teacher: makeTeacher(
          pricingType: SessionPricingType.free,
          price: null,
        ),
        pricing: paidQuote,
      ),
    );

    expect(find.textContaining('100'), findsOneWidget);
    expect(find.text('Free'), findsNothing);
  });

  testWidgets('paid quote in Arabic never shows «مجاني»', (tester) async {
    await pumpInApp(
      tester,
      QuranSessionPriceChip(
        teacher: makeTeacher(
          pricingType: SessionPricingType.free,
          price: null,
        ),
        pricing: paidQuote,
      ),
      locale: const Locale('ar'),
    );

    expect(find.text('مجاني'), findsNothing);
    expect(find.textContaining('100'), findsOneWidget);
  });

  testWidgets('free quote shows the free label', (tester) async {
    await pumpInApp(
      tester,
      QuranSessionPriceChip(
        teacher: makeTeacher(
          pricingType: SessionPricingType.fixedPerSession,
        ),
        pricing: freeQuote,
      ),
    );

    expect(find.text('Free'), findsOneWidget);
  });

  testWidgets('manual payment price wins over quote and shows paid', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      QuranSessionPriceChip(
        teacher: makeTeacher(
          manualPaymentPrice: const ManualPaymentPrice(
            amountMinor: 10000,
            currencyCode: 'EGP',
          ),
        ),
        pricing: freeQuote,
      ),
    );

    expect(find.text('Free'), findsNothing);
    expect(find.textContaining('100'), findsOneWidget);
  });
}
