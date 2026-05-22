import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Grateful post-purchase state — calm, not celebratory.
class SupportThankYouView extends StatelessWidget {
  const SupportThankYouView({
    super.key,
    required this.onDone,
  });

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spaceLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceLarge,
        children: [
          TilawaEmptyState(
            icon: Icons.favorite_outline,
            title: l10n.supportThankYouTitle,
            subtitle: l10n.supportThankYouBody,
          ),
          TilawaButton(
            text: l10n.supportDone,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}
