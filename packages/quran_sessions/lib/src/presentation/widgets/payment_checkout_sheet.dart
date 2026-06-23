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
  });

  final String amountLabel;
  final VoidCallback onConfirm;
  final bool isLoading;

  static Future<bool?> show(
    BuildContext context, {
    required String amountLabel,
    required Future<bool> Function() onConfirm,
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
              l10n.paymentCheckoutTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: tokens.spaceSmall),
            Text(
              l10n.paymentCheckoutAmount(amountLabel),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.primary,
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            Text(
              l10n.paymentCheckoutRefundToWalletNotice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            TilawaButton(
              text: l10n.paymentCheckoutConfirm,
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
