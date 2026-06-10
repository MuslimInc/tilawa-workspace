import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../cubit/tasbeeh_cubit.dart';
import '../../models/tasbeeh_counting_session.dart';
import 'tasbeeh_counter_card.dart';
import 'tasbeeh_layout_widgets.dart';

class TasbeehQuickCountView extends StatelessWidget {
  const TasbeehQuickCountView({
    super.key,
    required this.cubit,
    required this.session,
  });

  final TasbeehCubit cubit;
  final TasbeehEphemeralCountingSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TasbeehContentBounds(
      alignTop: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceMedium,
          tokens.spaceLarge,
          tokens.spaceLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.tasbeehQuickCountTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: tokens.spaceExtraSmall),
            Text(
              context.l10n.tasbeehQuickCountSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            Expanded(
              child: TasbeehCounterCard(
                displayCount: session.count,
                onTap: cubit.incrementEphemeralCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
