import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../cubit/tasbeeh_cubit.dart';
import '../../cubit/tasbeeh_state.dart';
import '../../models/tasbeeh_counting_session.dart';
import 'tasbeeh_layout_widgets.dart';

class TasbeehEphemeralCountingActions extends StatelessWidget {
  const TasbeehEphemeralCountingActions({
    super.key,
    required this.cubit,
    required this.session,
    required this.state,
  });

  final TasbeehCubit cubit;
  final TasbeehEphemeralCountingSession session;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final errorText = resolveTasbeehErrorText(context, state);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null) ...[
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
        ],
        TilawaButton(
          text: context.l10n.reset,
          variant: TilawaButtonVariant.outline,
          isFullWidth: true,
          onPressed: session.count > 0 ? cubit.resetEphemeralCount : null,
        ),
      ],
    );
  }
}

class TasbeehSavedDhikrCountingActions extends StatelessWidget {
  const TasbeehSavedDhikrCountingActions({
    super.key,
    required this.cubit,
    required this.session,
    required this.state,
  });

  final TasbeehCubit cubit;
  final TasbeehSavedDhikrCountingSession session;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final errorText = resolveTasbeehErrorText(context, state);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null) ...[
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
        ],
        TilawaButton(
          text: context.l10n.reset,
          variant: TilawaButtonVariant.outline,
          isFullWidth: true,
          onPressed: session.dhikr.count > 0
              ? cubit.resetActiveSavedDhikr
              : null,
        ),
      ],
    );
  }
}
