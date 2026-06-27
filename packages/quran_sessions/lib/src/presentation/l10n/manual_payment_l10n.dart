import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../config/manual_payment_pilot_config.dart';

/// Manual/off-app payment instructions shared by paid-session surfaces.
extension ManualPaymentInstructionsL10n on QuranSessionsLocalizations {
  /// Plain-text fallback for surfaces that cannot render structured links.
  String get manualPaymentInstructionsText => [
    manualPaymentInstructionsBody,
    manualPaymentInstapayHandle,
    ManualPaymentPilotConfig.instapayHandle,
    manualPaymentInstapayLink,
    ManualPaymentPilotConfig.instapayPaymentLink,
    manualPaymentRecipientMaskedName,
    ManualPaymentPilotConfig.recipientMaskedName,
    manualPaymentReceiptWhatsappInstruction,
    ManualPaymentPilotConfig.supportWhatsappNumber,
    manualPaymentConfirmationRule,
  ].join('\n');
}
