import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('ManualPaymentPilotConfig', () {
    test('uses corrected InstaPay handle and payment link', () {
      check(
        ManualPaymentPilotConfig.instapayHandle,
      ).equals('muhamadkamel@instapay');
      check(ManualPaymentPilotConfig.instapayPaymentLink).equals(
        'https://ipn.eg/S/muhamadkamel/instapay/6hkRRE',
      );
    });

    test('stores masked recipient name only', () {
      check(
        ManualPaymentPilotConfig.recipientMaskedName,
      ).equals('MOHAMED K**** H***** K****');
      check(
        ManualPaymentPilotConfig.recipientMaskedName.contains('KAMEL'),
      ).isFalse();
    });

    test('uses support WhatsApp number for receipt verification', () {
      check(
        ManualPaymentPilotConfig.supportWhatsappNumber,
      ).equals('+201060099009');
      check(
        ManualPaymentPilotConfig.supportWhatsappWaMeLink,
      ).equals('https://wa.me/201060099009');
    });
  });
}
