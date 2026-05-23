import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';

import '../../domain/constants/support_charities_constants.dart';
import 'support_charities_sheet.dart';

/// Trust footer line with tappable partner-charities link.
class SupportTrustLineText extends StatefulWidget {
  const SupportTrustLineText({super.key, required this.baseStyle});

  final TextStyle baseStyle;

  @override
  State<SupportTrustLineText> createState() => _SupportTrustLineTextState();
}

class _SupportTrustLineTextState extends State<SupportTrustLineText> {
  late final TapGestureRecognizer _linkRecognizer;

  @override
  void initState() {
    super.initState();
    _linkRecognizer = TapGestureRecognizer()..onTap = _onCharitiesLinkTap;
  }

  @override
  void dispose() {
    _linkRecognizer.dispose();
    super.dispose();
  }

  void _onCharitiesLinkTap() {
    if (!SupportCharitiesConstants.hasPartners) {
      return;
    }
    showSupportCharitiesSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool linkEnabled = SupportCharitiesConstants.hasPartners;

    final TextStyle linkStyle = widget.baseStyle.copyWith(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary.withValues(alpha: 0.4),
    );

    return Text.rich(
      TextSpan(
        style: widget.baseStyle,
        children: <InlineSpan>[
          TextSpan(text: l10n.supportTrustLinePrefix),
          TextSpan(
            text: l10n.supportCharitiesLinkLabel,
            style: linkStyle,
            recognizer: linkEnabled ? _linkRecognizer : null,
          ),
          TextSpan(text: l10n.supportTrustLineSuffix),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }
}
