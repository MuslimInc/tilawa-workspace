import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Minimal sandbox checkout — confirm button only (no PSP SDK).
class PaymentCheckoutSheet extends StatelessWidget {
  const PaymentCheckoutSheet({
    super.key,
    required this.amountLabel,
    required this.onConfirm,
    this.isLoading = false,
    this.isSandbox = true,
    this.isFreeSession = false,
  });

  final String amountLabel;
  final VoidCallback onConfirm;
  final bool isLoading;
  final bool isSandbox;
  final bool isFreeSession;

  static Future<bool?> show(
    BuildContext context, {
    required String amountLabel,
    required Future<bool> Function() onConfirm,
    bool isSandbox = true,
    bool isFreeSession = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var loading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return PaymentCheckoutSheet(
              amountLabel: amountLabel,
              isLoading: loading,
              isSandbox: isSandbox,
              isFreeSession: isFreeSession,
              onConfirm: () async {
                setState(() => loading = true);
                final ok = await onConfirm();
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop(ok);
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceSmall,
          tokens.spaceLarge,
          tokens.spaceLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isFreeSession
                  ? l10n.paymentCheckoutFreeTitle
                  : l10n.paymentCheckoutTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: tokens.spaceSmall),
            Text(
              isFreeSession
                  ? l10n.paymentCheckoutFreeAmount
                  : l10n.paymentCheckoutAmount(amountLabel),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isFreeSession ? scheme.primary : scheme.onSurface,
              ),
            ),
            if (isSandbox && !isFreeSession) ...[
              SizedBox(height: tokens.spaceMedium),
              TilawaFeedbackStrip(
                icon: Icons.science_outlined,
                message: l10n.paymentCheckoutSandboxNotice,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                variant: TilawaFeedbackVariant.info,
              ),
            ],
            if (!isFreeSession) ...[
              SizedBox(height: tokens.spaceMedium),
              Text(
                l10n.paymentCheckoutRefundToWalletNotice,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: tokens.spaceLarge),
            TilawaButton(
              text: isFreeSession
                  ? l10n.paymentCheckoutConfirmFree
                  : l10n.paymentCheckoutConfirm,
              onPressed: isLoading ? null : onConfirm,
              isLoading: isLoading,
              isFullWidth: true,
              size: TilawaButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}
