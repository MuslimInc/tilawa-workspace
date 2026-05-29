import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../cubit/tasbeeh_cubit.dart';
import '../../models/tasbeeh_counting_session.dart';
import 'tasbeeh_counter_card.dart';
import 'tasbeeh_layout_widgets.dart';

class TasbeehEphemeralCountingView extends StatelessWidget {
  const TasbeehEphemeralCountingView({
    super.key,
    required this.cubit,
    required this.session,
  });

  final TasbeehCubit cubit;
  final TasbeehEphemeralCountingSession session;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return TasbeehContentBounds(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: tokens.spaceSmall,
              runSpacing: tokens.spaceSmall,
              children: [
                TilawaButton(
                  text: context.l10n.tasbeehAddNewOptionTitle,
                  leadingIcon: const Icon(Icons.add_rounded),
                  variant: TilawaButtonVariant.outline,
                  onPressed: cubit.showCreateView,
                ),
                TilawaButton(
                  text: context.l10n.tasbeehViewHistoryOptionTitle,
                  leadingIcon: const Icon(Icons.history_rounded),
                  variant: TilawaButtonVariant.outline,
                  onPressed: cubit.showHistoryView,
                ),
              ],
            ),
            SizedBox(height: tokens.spaceMedium),
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
