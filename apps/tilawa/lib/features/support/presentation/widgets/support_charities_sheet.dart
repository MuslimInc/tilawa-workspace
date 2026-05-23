import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/constants/support_charities_constants.dart';
import '../support_partner_charity_labels.dart';

/// Lists partner charity links opened from the support trust line.
Future<void> showSupportCharitiesSheet(BuildContext context) {
  final l10n = context.l10n;
  final tokens = Theme.of(context).tokens;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return TilawaBottomSheetScaffold(
        topBar: TilawaBottomSheetTitleRow(
          title: l10n.supportCharitiesSheetTitle,
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLarge,
              0,
              tokens.spaceLarge,
              tokens.spaceLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceSmall,
              children: SupportCharitiesConstants.partners
                  .map(
                    (SupportPartnerCharity charity) =>
                        _CharityLinkTile(charity: charity),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      );
    },
  );
}

class _CharityLinkTile extends StatelessWidget {
  const _CharityLinkTile({required this.charity});

  final SupportPartnerCharity charity;

  Future<void> _open(BuildContext context) async {
    final Uri? uri = Uri.tryParse(charity.url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final String label = supportPartnerCharityLabel(context, charity.id);

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceMedium,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                FluentIcons.open_24_regular,
                size: tokens.iconSizeMedium,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
