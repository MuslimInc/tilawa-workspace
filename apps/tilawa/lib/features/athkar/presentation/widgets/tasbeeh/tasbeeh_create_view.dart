import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/constants/tasbeeh_constants.dart';
import '../../cubit/tasbeeh_cubit.dart';
import '../../cubit/tasbeeh_state.dart';
import 'tasbeeh_layout_widgets.dart';

class TasbeehCreateView extends StatelessWidget {
  const TasbeehCreateView({super.key, required this.cubit, required this.state});

  final TasbeehCubit cubit;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TasbeehContentBounds(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spaceLarge),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: TilawaCard(
                borderRadius: tokens.radiusExtraLarge,
                surface: TilawaCardSurface.raised,
                backgroundColor: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.tasbeehAddNewOptionTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: tokens.spaceMedium),
                    TilawaTextField(
                      hintText: context.l10n.tasbeehInputHint,
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      onChanged: cubit.updateDraftText,
                      maxLength: TasbeehConstants.maxTextLength,
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    TilawaTextField(
                      hintText: '${TasbeehConstants.defaultTargetCount}',
                      prefixIcon: const Icon(Icons.flag_rounded),
                      onChanged: cubit.updateDraftTargetText,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TasbeehCreateActions extends StatelessWidget {
  const TasbeehCreateActions({
    super.key,
    required this.cubit,
    required this.state,
  });

  final TasbeehCubit cubit;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final errorText = resolveTasbeehErrorText(context, state);
    final canSave =
        state.draftText.trim().isNotEmpty &&
        state.draftTargetText.trim().isNotEmpty;

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
          text: context.l10n.tasbeehGoToCounting,
          onPressed: canSave ? cubit.saveDraftDhikr : null,
          variant: TilawaButtonVariant.primary,
          isFullWidth: true,
        ),
      ],
    );
  }
}
