import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../boundaries/manual_payment_link_launcher.dart';
import '../../domain/entities/manual_payment_market_config.dart';

/// Structured manual/off-app payment instructions (InstaPay + WhatsApp receipt).
class ManualPaymentInstructions extends StatelessWidget {
  const ManualPaymentInstructions({
    super.key,
    this.whatsappUrl,
    this.config = ManualPaymentMarketConfig.egFallback,
  });

  final String? whatsappUrl;

  /// Per-market manual payment details (resolved from the market config).
  final ManualPaymentMarketConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.primary,
      height: 1.4,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
    final monoStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurface,
      height: 1.4,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.manualPaymentInstructionsBody, style: bodyStyle),
        SizedBox(height: tokens.spaceSmall),
        Text(l10n.manualPaymentInstapayHandle, style: bodyStyle),
        SelectableText(config.instapayHandle ?? '', style: monoStyle),
        SizedBox(height: tokens.spaceExtraSmall),
        Text(l10n.manualPaymentInstapayLink, style: bodyStyle),
        _ManualPaymentLinkText(
          label: config.instapayPaymentLink ?? '',
          onTap: () => _openUrl(context, config.instapayPaymentLink ?? ''),
          style: linkStyle,
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(l10n.manualPaymentRecipientMaskedName, style: bodyStyle),
        SelectableText(config.recipientMaskedName ?? '', style: monoStyle),
        SizedBox(height: tokens.spaceSmall),
        Text(l10n.manualPaymentReceiptWhatsappInstruction, style: bodyStyle),
        _ManualPaymentLinkText(
          label: config.supportWhatsappNumber,
          onTap: () => _openWhatsApp(context),
          style: linkStyle,
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(l10n.manualPaymentConfirmationRule, style: bodyStyle),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final l10n = context.quranSessionsL10n;
    final launcher = ManualPaymentLinkLauncher.launchUrl;
    if (launcher != null && await launcher(url)) {
      return;
    }
    if (!context.mounted) return;
    await _copyFallback(context, l10n, url);
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final l10n = context.quranSessionsL10n;
    final url = whatsappUrl;
    if (url == null || url.isEmpty) {
      final phone = config.supportWhatsappNumber;
      final launcher = ManualPaymentLinkLauncher.launchWhatsApp;
      if (launcher != null && await launcher(phone)) {
        return;
      }
    }
    final urlLauncher = ManualPaymentLinkLauncher.launchUrl;
    final waLink = url ?? config.supportWhatsappWaMeLink;
    if (urlLauncher != null && await urlLauncher(waLink)) {
      return;
    }
    if (!context.mounted) return;
    await _copyFallback(
      context,
      l10n,
      url == null ? config.supportWhatsappNumber : waLink,
    );
  }

  Future<void> _copyFallback(
    BuildContext context,
    QuranSessionsLocalizations l10n,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    TilawaFeedback.showToast(
      context,
      message: l10n.manualPaymentCopiedToClipboard,
      variant: TilawaFeedbackVariant.info,
    );
  }
}

class _ManualPaymentLinkText extends StatelessWidget {
  const _ManualPaymentLinkText({
    required this.label,
    required this.onTap,
    required this.style,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Theme.of(context).tokens.radiusSmall),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: Theme.of(context).tokens.spaceTiny,
        ),
        child: SelectableText(label, style: style),
      ),
    );
  }
}
