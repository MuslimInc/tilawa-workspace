/// Centralized manual/off-app payment details for the Egypt Closed Testing pilot.
///
/// Presentation-only — not read by booking, payment provider, commission, or
/// payout logic. Values are shared by paid-session notice and pending-state
/// copy builders.
abstract final class ManualPaymentPilotConfig {
  /// InstaPay handle shown to students for manual transfer.
  static const String instapayHandle = 'muhamadkamel@instapay';

  /// InstaPay payment link (opens externally when supported).
  static const String instapayPaymentLink =
      'https://ipn.eg/S/muhamadkamel/instapay/6hkRRE';

  /// Masked recipient name exactly as shown on the InstaPay confirmation screen.
  /// Never store or display the full legal name in the app.
  static const String recipientMaskedName = 'MOHAMED K**** H***** K****';

  /// Support WhatsApp number for payment receipt verification (E.164).
  static const String supportWhatsappNumber = '+201060099009';

  /// WhatsApp deep link derived from [supportWhatsappNumber].
  static String get supportWhatsappWaMeLink {
    final digits = supportWhatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
    return 'https://wa.me/$digits';
  }
}
