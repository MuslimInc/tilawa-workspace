import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
// ignore: implementation_imports
import 'package:quran_sessions/src/utils/dob_validator.dart';
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
        SizedBox(height: tokens.spaceMedium),
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
        SizedBox(height: tokens.spaceMedium),
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
        Text(qsL10n.profileFieldGender, style: theme.textTheme.titleSmall),
        SizedBox(height: tokens.spaceSmall),
        _GenderPickerRow(
          maleLabel: qsL10n.gender_male,
          femaleLabel: qsL10n.gender_female,
          selected: state.draft.gender == null
              ? null
              : UserGender.values.byName(state.draft.gender!),
          onChanged: cubit.genderSelected,
        ),
        TilawaFormSectionError(
          errorText: localizedRegistrationFieldError(
            state.fieldError('gender'),
            context.l10n,
          ),
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        Text(qsL10n.profileFieldDateOfBirth, style: theme.textTheme.titleSmall),
        SizedBox(height: tokens.spaceSmall),
        _DateOfBirthPicker(
          selected: state.draft.dateOfBirth,
          minimumAgeYears: state.minimumStudentAgeYears,
          label: qsL10n.profileFieldDateOfBirth,
          placeholder: qsL10n.profileCompletionSelectDateOfBirth,
          errorText: localizedRegistrationFieldError(
            state.fieldError('dateOfBirth'),
            context.l10n,
          ),
          onChanged: cubit.dateOfBirthSet,
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        Text(qsL10n.profileFieldCountry, style: theme.textTheme.titleSmall),
        SizedBox(height: tokens.spaceSmall),
        _CountryDropdown(
          countries: state.availableCountries,
          selected: state.selectedCountry,
          readOnly: state.countryPickerLocked,
          label: qsL10n.profileFieldCountry,
          placeholder: qsL10n.profileCompletionSelectCountry,
          errorText: localizedRegistrationFieldError(
            state.fieldError('country'),
            context.l10n,
          ),
          onChanged: cubit.countrySelected,
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        Text(qsL10n.profileFieldCity, style: theme.textTheme.titleSmall),
        SizedBox(height: tokens.spaceSmall),
        _CityDropdown(
          cities: state.availableCities,
          selected: state.selectedCity,
          countrySelected: state.selectedCountry != null,
          isLoading: state.isLoadingCities,
          readOnly: state.cityPickerLocked,
          label: qsL10n.profileFieldCity,
          loadingHint: qsL10n.profileCompletionLoadingCities,
          selectCityHint: qsL10n.profileCompletionSelectCity,
          selectCountryFirstHint: qsL10n.profileCompletionSelectCountryFirst,
          errorText: localizedRegistrationFieldError(
            state.fieldError('city'),
            context.l10n,
          ),
          onChanged: cubit.citySelected,
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

class EmailRegistrationLearningStep extends StatelessWidget {
  const EmailRegistrationLearningStep({super.key});

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
          context.l10n.registrationStepLearningDescription,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        Text(
          qsL10n.profileFieldLearningGoals,
          style: theme.textTheme.titleSmall,
        ),
        SizedBox(height: tokens.spaceExtraSmall),
        Text(
          qsL10n.profileLearningGoalsHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        Wrap(
          spacing: tokens.spaceSmall,
          runSpacing: tokens.spaceSmall,
          children: <Widget>[
            for (final StudentLearningGoal goal in kStudentLearningGoalOptions)
              TilawaSelectionPill(
                label: qsL10n.specializationLabel(goal.name),
                selected: state.draft.learningGoals.contains(goal.name),
                onTap: () => cubit.learningGoalToggled(goal),
              ),
          ],
        ),
        TilawaFormSectionError(
          errorText: localizedRegistrationFieldError(
            state.fieldError('learningGoals'),
            context.l10n,
          ),
        ),
        if (state.requiresGuardianStep) ...<Widget>[
          SizedBox(height: tokens.spaceLarge),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: Text(
                context.l10n.registrationMinorNotice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class EmailRegistrationGuardianStep extends StatelessWidget {
  const EmailRegistrationGuardianStep({super.key});

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
        TilawaStateVisual(
          icon: Icons.family_restroom_outlined,
          size: tokens.iconSizeExtraLarge + tokens.spaceExtraLarge,
        ),
        SizedBox(height: tokens.spaceLarge),
        Text(
          context.l10n.registrationGuardianStepTitle,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          context.l10n.registrationStepGuardianDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        CheckboxListTile(
          value: state.draft.guardianConsentAcknowledged,
          onChanged: (bool? value) =>
              cubit.guardianConsentToggled(value ?? false),
          title: Text(context.l10n.registrationGuardianConsentLabel),
          subtitle: Text(qsL10n.guardianApprovalBody),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        TilawaFormSectionError(
          errorText: localizedRegistrationFieldError(
            state.fieldError('guardianConsent'),
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
          label: qsL10n.profileFieldGender,
          value: state.draft.gender == null
              ? ''
              : (state.draft.gender == UserGender.female.name
                    ? qsL10n.gender_female
                    : qsL10n.gender_male),
        ),
        _ReviewRow(
          label: qsL10n.profileFieldCountry,
          value: state.draft.countryName ?? '',
        ),
        _ReviewRow(
          label: qsL10n.profileFieldCity,
          value: state.draft.cityName ?? '',
        ),
        _ReviewRow(
          label: l10n.registrationPreferredLanguageLabel,
          value: languageLabel,
        ),
        _ReviewRow(
          label: qsL10n.profileFieldLearningGoals,
          value: state.draft.learningGoals
              .map((String goal) => qsL10n.specializationLabel(goal))
              .join(', '),
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

class _GenderPickerRow extends StatelessWidget {
  const _GenderPickerRow({
    required this.maleLabel,
    required this.femaleLabel,
    required this.selected,
    required this.onChanged,
  });

  final String maleLabel;
  final String femaleLabel;
  final UserGender? selected;
  final ValueChanged<UserGender> onChanged;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return Row(
      children: <Widget>[
        Expanded(
          child: TilawaSelectionPill(
            label: maleLabel,
            selected: selected == UserGender.male,
            onTap: () => onChanged(UserGender.male),
          ),
        ),
        SizedBox(width: tokens.spaceMedium),
        Expanded(
          child: TilawaSelectionPill(
            label: femaleLabel,
            selected: selected == UserGender.female,
            onTap: () => onChanged(UserGender.female),
          ),
        ),
      ],
    );
  }
}

class _DateOfBirthPicker extends StatelessWidget {
  const _DateOfBirthPicker({
    required this.selected,
    required this.minimumAgeYears,
    required this.label,
    required this.placeholder,
    required this.onChanged,
    this.errorText,
  });

  final DateTime? selected;
  final int minimumAgeYears;
  final String label;
  final String placeholder;
  final String? errorText;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String locale = Localizations.localeOf(context).toString();
    final DateFormat dateFmt = DateFormat.yMMMMd(locale);

    return TilawaReadOnlyField(
      prefixIcon: Icons.calendar_today_outlined,
      errorText: errorText,
      semanticLabel: label,
      onTap: () async {
        final DateTime firstDate = DobValidator.earliest;
        final DateTime lastDate = DobValidator.latestBirthDate(
          minimumAgeYears: minimumAgeYears,
        );
        var initialDate = selected ?? lastDate;
        if (initialDate.isAfter(lastDate)) {
          initialDate = lastDate;
        }
        if (initialDate.isBefore(firstDate)) {
          initialDate = firstDate;
        }
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: placeholder,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Text(
        selected == null ? placeholder : dateFmt.format(selected!),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: selected == null ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({
    required this.countries,
    required this.selected,
    required this.onChanged,
    required this.label,
    required this.placeholder,
    this.readOnly = false,
    this.errorText,
  });

  final List<MarketCountry> countries;
  final MarketCountry? selected;
  final ValueChanged<MarketCountry> onChanged;
  final String label;
  final String placeholder;
  final bool readOnly;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final String selectedLabel = selected == null
        ? placeholder
        : _countryLabel(selected!);

    if (readOnly && selected != null) {
      return TilawaDropdownField<MarketCountry>(
        value: selected,
        hintText: selectedLabel,
        semanticLabel: label,
        prefixIcon: Icons.public_outlined,
        enabled: false,
        errorText: errorText,
        items: <TilawaDropdownItem<MarketCountry>>[
          TilawaDropdownItem<MarketCountry>(
            value: selected!,
            label: selectedLabel,
          ),
        ],
        onChanged: null,
      );
    }

    return TilawaDropdownField<MarketCountry>(
      value: selected,
      hintText: placeholder,
      semanticLabel: label,
      prefixIcon: Icons.public_outlined,
      errorText: errorText,
      items: <TilawaDropdownItem<MarketCountry>>[
        for (final MarketCountry country in countries)
          TilawaDropdownItem<MarketCountry>(
            value: country,
            label: _countryLabel(country),
          ),
      ],
      onChanged: onChanged,
    );
  }

  String _countryLabel(MarketCountry country) {
    final String? flag = country.flagEmoji;
    if (flag == null || flag.isEmpty) {
      return country.countryName;
    }
    return '$flag ${country.countryName}';
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({
    required this.cities,
    required this.selected,
    required this.countrySelected,
    required this.onChanged,
    required this.label,
    required this.loadingHint,
    required this.selectCityHint,
    required this.selectCountryFirstHint,
    this.isLoading = false,
    this.readOnly = false,
    this.errorText,
  });

  final List<MarketCity> cities;
  final MarketCity? selected;
  final bool countrySelected;
  final bool isLoading;
  final bool readOnly;
  final ValueChanged<MarketCity> onChanged;
  final String label;
  final String loadingHint;
  final String selectCityHint;
  final String selectCountryFirstHint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return TilawaDropdownField<MarketCity>(
        value: null,
        hintText: loadingHint,
        semanticLabel: label,
        prefixIcon: Icons.location_city_outlined,
        enabled: false,
        items: const <TilawaDropdownItem<MarketCity>>[],
        onChanged: null,
      );
    }

    if (readOnly && selected != null) {
      return TilawaDropdownField<MarketCity>(
        value: selected,
        hintText: selected!.cityName,
        semanticLabel: label,
        prefixIcon: Icons.location_city_outlined,
        enabled: false,
        errorText: errorText,
        items: <TilawaDropdownItem<MarketCity>>[
          TilawaDropdownItem<MarketCity>(
            value: selected!,
            label: selected!.cityName,
          ),
        ],
        onChanged: null,
      );
    }

    return TilawaDropdownField<MarketCity>(
      value: selected,
      hintText: countrySelected ? selectCityHint : selectCountryFirstHint,
      semanticLabel: label,
      prefixIcon: Icons.location_city_outlined,
      enabled: countrySelected,
      errorText: errorText,
      items: <TilawaDropdownItem<MarketCity>>[
        for (final MarketCity city in cities)
          TilawaDropdownItem<MarketCity>(value: city, label: city.cityName),
      ],
      onChanged: countrySelected ? onChanged : null,
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
      children: <Widget>[
        Expanded(
          child: TilawaSelectionPill(
            label: arabicLabel,
            selected: selected == arabicLanguageCode,
            onTap: () => onChanged(arabicLanguageCode),
          ),
        ),
        SizedBox(width: tokens.spaceMedium),
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
    EmailRegistrationStep.quranLearning => l10n.registrationStepLearningTitle,
    EmailRegistrationStep.guardian => l10n.registrationStepGuardianTitle,
    EmailRegistrationStep.review => l10n.registrationStepReviewTitle,
  };
}
