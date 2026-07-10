import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('ManualPaymentMarketConfig.egFallback', () {
    const cfg = ManualPaymentMarketConfig.egFallback;

    test('resolves EGP currency and Egypt support number', () {
      check(cfg.currencyCode).equals('EGP');
      check(cfg.supportWhatsappNumber).equals('+201060099009');
    });

    test('uses corrected InstaPay handle and payment link', () {
      check(cfg.instapayHandle).equals('muhamadkamel@instapay');
      check(
        cfg.instapayPaymentLink,
      ).equals('https://ipn.eg/S/muhamadkamel/instapay/6hkRRE');
    });

    test('exposes Vodafone Cash as a manual method', () {
      check(cfg.vodafoneCashNumber).equals('+201060099009');
    });

    test('stores masked recipient name only', () {
      check(cfg.recipientMaskedName).equals('MOHAMED K**** H***** K****');
      check(cfg.recipientMaskedName!.contains('KAMEL')).isFalse();
    });

    test('derives the wa.me link from the support number', () {
      check(cfg.supportWhatsappWaMeLink).equals('https://wa.me/201060099009');
    });

    test('buildWhatsappPrefillUrl embeds the receipt details', () {
      final url = cfg.buildWhatsappPrefillUrl(
        paymentReference: 'REF123',
        teacher: 'Ustadh',
        dateTime: 'Mon 10:00',
        amount: '100 EGP',
        paymentMethod: 'InstaPay',
      );
      check(url).startsWith('https://wa.me/201060099009?text=');
      check(Uri.decodeFull(url)).contains('REF123');
    });
  });
}
