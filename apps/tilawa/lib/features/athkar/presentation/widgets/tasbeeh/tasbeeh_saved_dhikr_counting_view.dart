import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../cubit/tasbeeh_cubit.dart';
import '../../models/tasbeeh_counting_session.dart';
import 'tasbeeh_counter_card.dart';
import 'tasbeeh_layout_widgets.dart';

class TasbeehSavedDhikrCountingView extends StatelessWidget {
  const TasbeehSavedDhikrCountingView({
    super.key,
    required this.cubit,
    required this.session,
  });

  final TasbeehCubit cubit;
  final TasbeehSavedDhikrCountingSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final dhikr = session.dhikr;

    return TasbeehContentBounds(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dhikr.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: tokens.spaceSmall),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TilawaStatusChip(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceMedium,
                  vertical: tokens.spaceSmall,
                ),
                icon: Icons.flag_rounded,
                label: context.l10n.tasbeehCurrentTarget(dhikr.targetCount),
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            Expanded(
              child: TasbeehCounterCard(
                displayCount: dhikr.count,
                progress: session.progress,
                targetFeedbackPulse: session.targetFeedbackPulse,
                onTap: cubit.incrementActiveSavedDhikr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
