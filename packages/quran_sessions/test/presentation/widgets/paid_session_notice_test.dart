import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/widgets/paid_session_notice.dart';

import '../../helpers/widget_pump.dart';

void main() {
  const price = ManualPaymentPrice(amountMinor: 10000, currencyCode: 'EGP');

  testWidgets('shows manual payment verification details in English', (
    tester,
  ) async {
    await pumpInApp(tester, const PaidSessionNotice(price: price));

    expect(find.textContaining('100'), findsOneWidget);
    expect(find.textContaining('ج.م.'), findsOneWidget);
    expect(find.text('Vodafone Cash'), findsOneWidget);
    expect(find.text('InstaPay'), findsOneWidget);
    expect(find.text('Bank transfer'), findsOneWidget);
    expect(find.text('muhamadkamel@instapay'), findsOneWidget);
    expect(
      find.textContaining('https://ipn.eg/S/muhamadkamel/instapay/6hkRRE'),
      findsOneWidget,
    );
    expect(
      find.textContaining('MOHAMED K**** H***** K****'),
      findsOneWidget,
    );
    expect(find.textContaining('+201060099009'), findsOneWidget);
    expect(
      find.textContaining('screenshot of the transfer receipt'),
      findsOneWidget,
    );
    expect(find.textContaining('MOHAMED KAMEL'), findsNothing);
    expect(find.text('Free'), findsNothing);
  });

  testWidgets('shows manual payment verification details in Arabic', (
    tester,
  ) async {
    await pumpInApp(
      tester,
      const PaidSessionNotice(price: price),
      locale: const Locale('ar'),
      textDirection: TextDirection.rtl,
    );

    expect(find.textContaining('100'), findsOneWidget);
    expect(find.textContaining('ج.م.'), findsOneWidget);
    expect(find.text('Vodafone Cash'), findsOneWidget);
    expect(find.text('InstaPay'), findsOneWidget);
    expect(find.text('تحويل بنكي'), findsOneWidget);
    expect(find.text('muhamadkamel@instapay'), findsOneWidget);
    expect(
      find.textContaining('https://ipn.eg/S/muhamadkamel/instapay/6hkRRE'),
      findsOneWidget,
    );
    expect(
      find.textContaining('MOHAMED K**** H***** K****'),
      findsOneWidget,
    );
    expect(find.textContaining('+201060099009'), findsOneWidget);
    expect(find.textContaining('إرسال صورة التحويل'), findsOneWidget);
    expect(find.textContaining('MOHAMED KAMEL'), findsNothing);
    expect(find.text('مجاني'), findsNothing);
  });
}
