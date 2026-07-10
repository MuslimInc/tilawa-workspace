import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/l10n/manual_payment_l10n.dart';

void main() {
  test(
    'manualPaymentInstructionsText includes centralized InstaPay values',
    () {
      const cfg = ManualPaymentMarketConfig.egFallback;
      final l10n = lookupQuranSessionsLocalizations(const Locale('en'));
      final text = l10n.manualPaymentInstructionsText();

      check(text).contains(l10n.manualPaymentInstructionsBody);
      check(text).contains(cfg.instapayHandle!);
      check(text).contains(cfg.instapayPaymentLink!);
      check(text).contains(cfg.recipientMaskedName!);
      check(text).contains(cfg.supportWhatsappNumber);
      check(text).contains(l10n.manualPaymentConfirmationRule);
      check(text.toLowerCase().contains('free session')).isFalse();
    },
  );

  test('manual payment cancellation keys are separate from instructions', () {
    final l10n = lookupQuranSessionsLocalizations(const Locale('en'));
    final instructions = l10n.manualPaymentInstructionsText();

    check(
      instructions.contains(l10n.manualPaymentCancellationPolicy),
    ).isFalse();
    check(
      instructions.contains(
        l10n.manualPaymentCancellationSupportHint(
          ManualPaymentMarketConfig.egFallback.supportWhatsappNumber,
        ),
      ),
    ).isFalse();
  });
}
