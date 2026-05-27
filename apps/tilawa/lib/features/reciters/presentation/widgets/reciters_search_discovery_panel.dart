import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'reciter_card.dart';

/// Calm discovery surface shown while reciter search is focused and empty.
class RecitersSearchDiscoveryPanel extends StatelessWidget {
  const RecitersSearchDiscoveryPanel({
    super.key,
    required this.suggestedReciters,
  });

  final List<ReciterEntity> suggestedReciters;

  @override
  Widget build(BuildContext context) {
    if (suggestedReciters.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;

    return AnimatedSwitcher(
      duration: tokens.durationFast,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey<int>(suggestedReciters.length),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.recitersSearchSuggestedTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: tokens.spaceSmall),
            ...suggestedReciters.map((ReciterEntity reciter) {
              return Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSmall),
                child: ReciterCard(
                  key: ValueKey('suggested_${reciter.id}'),
                  reciter: reciter,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
