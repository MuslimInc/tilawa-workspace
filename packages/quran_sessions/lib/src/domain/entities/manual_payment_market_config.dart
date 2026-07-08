import 'package:equatable/equatable.dart';

/// Market-based manual / off-app payment details.
///
/// Sourced from the per-market Firestore doc
/// (`quran_session_market_configs/{countryCode}`) via [MarketConfig.manualPayment]
/// so payment instructions are configured per enabled market — never hardcoded.
///
/// Scope is intentionally manual/off-app only: no wallet, no checkout, no PSP.
/// The student transfers via the configured local methods and sends proof to
/// WhatsApp support; an admin verifies before the session is scheduled.
class ManualPaymentMarketConfig extends Equatable {
  const ManualPaymentMarketConfig({
    required this.currencyCode,
    required this.supportWhatsappNumber,
    this.instapayHandle,
    this.instapayPaymentLink,
    this.recipientMaskedName,
    this.vodafoneCashNumber,
  });

  /// ISO 4217 code, e.g. `EGP`.
  final String currencyCode;

  /// Support WhatsApp number for payment-receipt verification (E.164).
  final String supportWhatsappNumber;

  /// InstaPay handle shown to students for manual transfer.
  final String? instapayHandle;

  /// InstaPay payment link (opens externally when supported).
  final String? instapayPaymentLink;

  /// Masked recipient name exactly as shown on the InstaPay confirmation screen.
  final String? recipientMaskedName;

  /// Vodafone Cash number for manual transfer.
  final String? vodafoneCashNumber;

  /// Default Egypt configuration — the only enabled market in this release.
  /// Used as a safe fallback when a market doc omits the manual-payment block.
  static const ManualPaymentMarketConfig egFallback = ManualPaymentMarketConfig(
    currencyCode: 'EGP',
    supportWhatsappNumber: '+201060099009',
    instapayHandle: 'muhamadkamel@instapay',
    instapayPaymentLink: 'https://ipn.eg/S/muhamadkamel/instapay/6hkRRE',
    recipientMaskedName: 'MOHAMED K**** H***** K****',
    vodafoneCashNumber: '+201060099009',
  );

  /// WhatsApp deep link derived from [supportWhatsappNumber].
  String get supportWhatsappWaMeLink {
    final digits = supportWhatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
    return 'https://wa.me/$digits';
  }

  /// Prefilled WhatsApp URL carrying the manual-payment receipt details.
  String buildWhatsappPrefillUrl({
    required String paymentReference,
    required String teacher,
    required String dateTime,
    required String amount,
    required String paymentMethod,
  }) {
    final digits = supportWhatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
    final message = [
      'Quran Sessions manual payment receipt',
      'Payment reference: $paymentReference',
      'Teacher: $teacher',
      'Date/time: $dateTime',
      'Amount: $amount',
      'Payment method: $paymentMethod',
    ].join('\n');
    return Uri.https('wa.me', '/$digits', {'text': message}).toString();
  }

  @override
  List<Object?> get props => [
    currencyCode,
    supportWhatsappNumber,
    instapayHandle,
    instapayPaymentLink,
    recipientMaskedName,
    vodafoneCashNumber,
  ];
}
