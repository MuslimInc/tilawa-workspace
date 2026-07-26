import 'package:flutter/material.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class SadaqahJariyahFooter extends StatelessWidget {
  const SadaqahJariyahFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final l10n = context.l10n;
    final bool supportEnabled = getIt.isRegistered<AppLaunchConfig>()
        ? getIt<AppLaunchConfig>().supportTilawaEnabled
        : AppLaunchConfig.fromEnvironment().supportTilawaEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.sadaqahJariyahFooterDisclaimer,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: tokens.textHeightLoose,
          ),
        ),
        if (supportEnabled) ...[
          SizedBox(height: tokens.spaceSmall),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TilawaButton(
              text: l10n.supportTilawa,
              variant: TilawaButtonVariant.ghost,
              size: TilawaButtonSize.small,
              onPressed: () => const SupportRoute().push<void>(context),
            ),
          ),
        ],
      ],
    );
  }
}
