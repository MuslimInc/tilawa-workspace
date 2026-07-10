import 'package:checks/checks.dart';
import 'package:quran_sessions/src/data/dtos/market_config_dto.dart';
import 'package:quran_sessions/src/data/mappers/market_config_mapper.dart';
import 'package:test/test.dart';

MarketConfigDto _dto({
  bool manualPaymentEnabled = true,
  String? supportWhatsappNumber = '+201060099009',
}) => MarketConfigDto(
  countryCode: 'EG',
  countryName: 'مصر',
  currencyCode: 'EGP',
  defaultCityId: 'cairo',
  cities: const [],
  isEnabled: true,
  minSessionPrice: 100,
  maxSessionPrice: 2000,
  platformCommissionPercent: 15,
  manualPaymentEnabled: manualPaymentEnabled,
  supportWhatsappNumber: supportWhatsappNumber,
  instapayHandle: 'muhamadkamel@instapay',
  instapayPaymentLink: 'https://ipn.eg/S/muhamadkamel/instapay/6hkRRE',
  recipientMaskedName: 'MOHAMED K**** H***** K****',
  vodafoneCashNumber: '+201060099009',
);

void main() {
  group('MarketConfig manual payment mapping', () {
    test('resolves the per-market manual payment block for Egypt', () {
      final market = _dto().toDomain();
      final manual = market.manualPayment;
      check(manual).isNotNull();
      check(manual!.currencyCode).equals('EGP');
      check(manual.supportWhatsappNumber).equals('+201060099009');
      check(manual.instapayHandle).equals('muhamadkamel@instapay');
      check(manual.vodafoneCashNumber).equals('+201060099009');
    });

    test('is null when manual payment is disabled for the market', () {
      final market = _dto(manualPaymentEnabled: false).toDomain();
      check(market.manualPayment).isNull();
    });

    test('is null when the support WhatsApp number is missing', () {
      final market = _dto(supportWhatsappNumber: null).toDomain();
      check(market.manualPayment).isNull();
    });
  });
}
