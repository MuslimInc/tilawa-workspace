import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:tilawa_core/config/language_config.dart';

import '../../domain/entities/email_registration_step.dart';
import '../cubit/email_registration_cubit.dart';
import '../cubit/email_registration_state.dart';
import '../services/email_registration_error_messages.dart';

class EmailRegistrationAccountStep extends StatelessWidget {
  const EmailRegistrationAccountStep({super.key});

  @override
  Widget build(BuildContext context) {
    final EmailRegistrationState state = context
        .watch<EmailRegistrationCubit>()
        .state;
    final EmailRegistrationCubit cubit = context.read<EmailRegistrationCubit>();
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.l10n.registrationStepAccountDescription,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceMedium,
          children: <Widget>[
            TilawaTextField(
              label: context.l10n.emailAddress,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: cubit.emailChanged,
              errorText: localizedRegistrationFieldError(
                state.fieldError('email'),
                context.l10n,
              ),
            ),
            TilawaTextField(
              label: context.l10n.password,
              isPassword: true,
              textInputAction: TextInputAction.next,
              onChanged: cubit.passwordChanged,
              errorText: localizedRegistrationFieldError(
                state.fieldError('password'),
                context.l10n,
              ),
            ),
            TilawaTextField(
              label: context.l10n.confirmPassword,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onChanged: cubit.confirmPasswordChanged,
              errorText: localizedRegistrationFieldError(
                state.fieldError('confirmPassword'),
                context.l10n,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class EmailRegistrationPersonalStep extends StatelessWidget {
  const EmailRegistrationPersonalStep({super.key});

  @override
  Widget build(BuildContext context) {
    final EmailRegistrationState state = context
        .watch<EmailRegistrationCubit>()
        .state;
    final EmailRegistrationCubit cubit = context.read<EmailRegistrationCubit>();
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final QuranSessionsLocalizations qsL10n = context.quranSessionsL10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.l10n.registrationStepPersonalDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        TilawaTextField(
          label: qsL10n.profileFieldDisplayName,
          textInputAction: TextInputAction.next,
          onChanged: cubit.displayNameChanged,
          errorText: localizedRegistrationFieldError(
            state.fieldError('displayName'),
            context.l10n,
          ),
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        Text(
          context.l10n.registrationPreferredLanguageLabel,
          style: theme.textTheme.titleSmall,
        ),
        SizedBox(height: tokens.spaceSmall),
        _LanguagePicker(
          selected: state.draft.preferredLanguageCode,
          arabicLabel: context.l10n.arabic,
          englishLabel: context.l10n.english,
          onChanged: cubit.preferredLanguageSelected,
        ),
        TilawaFormSectionError(
          errorText: localizedRegistrationFieldError(
            state.fieldError('preferredLanguage'),
            context.l10n,
          ),
        ),
      ],
    );
  }
}

class EmailRegistrationReviewStep extends StatelessWidget {
  const EmailRegistrationReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final EmailRegistrationState state = context
        .watch<EmailRegistrationCubit>()
        .state;
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final QuranSessionsLocalizations qsL10n = context.quranSessionsL10n;
    final AppLocalizations l10n = context.l10n;

    final String languageLabel = switch (state.draft.preferredLanguageCode) {
      arabicLanguageCode => l10n.arabic,
      englishLanguageCode => l10n.english,
      _ => state.draft.preferredLanguageCode ?? '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.registrationStepReviewDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        _ReviewRow(label: l10n.emailAddress, value: state.draft.email.trim()),
        _ReviewRow(
          label: qsL10n.profileFieldDisplayName,
          value: state.draft.displayName.trim(),
        ),
        _ReviewRow(
          label: l10n.registrationPreferredLanguageLabel,
          value: languageLabel,
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.selected,
    required this.arabicLabel,
    required this.englishLabel,
    required this.onChanged,
  });

  final String? selected;
  final String arabicLabel;
  final String englishLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return Row(
      spacing: tokens.spaceMedium,
      children: <Widget>[
        Expanded(
          child: TilawaSelectionPill(
            label: arabicLabel,
            selected: selected == arabicLanguageCode,
            onTap: () => onChanged(arabicLanguageCode),
          ),
        ),
        Expanded(
          child: TilawaSelectionPill(
            label: englishLabel,
            selected: selected == englishLanguageCode,
            onTap: () => onChanged(englishLanguageCode),
          ),
        ),
      ],
    );
  }
}

String registrationStepLabel(
  BuildContext context,
  EmailRegistrationStep step,
) {
  final AppLocalizations l10n = context.l10n;
  return switch (step) {
    EmailRegistrationStep.account => l10n.registrationStepAccountTitle,
    EmailRegistrationStep.personal => l10n.registrationStepPersonalTitle,
    EmailRegistrationStep.review => l10n.registrationStepReviewTitle,
  };
}
