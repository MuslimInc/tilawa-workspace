import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/support_product.dart';
import 'support_tier_card.dart';

/// Confirms support tier before opening Google Play.
Future<bool?> showSupportConfirmationSheet(
  BuildContext context, {
  required SupportProduct product,
}) {
  final l10n = context.l10n;
  final tokens = Theme.of(context).tokens;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return TilawaBottomSheetScaffold(
        topBar: TilawaBottomSheetTitleRow(title: l10n.supportConfirmationTitle),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLarge,
            ).copyWith(bottom: tokens.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceLarge,
              children: [
                IgnorePointer(
                  child: SupportTierCard(
                    product: product,
                    selected: true,
                    onTap: () {},
                    compact: true,
                  ),
                ),
                Text(
                  l10n.supportConfirmationBody,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    height: tokens.textHeightLoose,
                  ),
                ),
                TilawaButton(
                  text: l10n.supportConfirm,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
                TilawaButton(
                  text: l10n.supportCancel,
                  variant: TilawaButtonVariant.ghost,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
