import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../../domain/entities/manual_payment_market_config.dart';

/// Manual/off-app payment instructions shared by paid-session surfaces.
extension ManualPaymentInstructionsL10n on QuranSessionsLocalizations {
  /// Plain-text fallback for surfaces that cannot render structured links.
  String manualPaymentInstructionsText([
    ManualPaymentMarketConfig config = ManualPaymentMarketConfig.egFallback,
  ]) => [
    manualPaymentInstructionsBody,
    manualPaymentInstapayHandle,
    config.instapayHandle ?? '',
    manualPaymentInstapayLink,
    config.instapayPaymentLink ?? '',
    manualPaymentRecipientMaskedName,
    config.recipientMaskedName ?? '',
    manualPaymentReceiptWhatsappInstruction,
    config.supportWhatsappNumber,
    manualPaymentConfirmationRule,
  ].join('\n');
}
