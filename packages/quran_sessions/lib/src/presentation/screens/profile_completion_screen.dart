import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/market_city.dart';
import '../../domain/entities/market_country.dart';
import '../../domain/entities/user_profile.dart';
import '../../utils/dob_validator.dart';
import '../blocs/profile_completion/profile_completion_bloc.dart';
import '../blocs/profile_completion/profile_completion_event.dart';
import '../blocs/profile_completion/profile_completion_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../forms/profile_completion_field_ids.dart';
import '../widgets/quran_sessions_scaffold.dart';

/// Gate screen shown before booking when the student's profile is incomplete.
///
/// Collects: gender, date of birth, country, city, and optional learning goals.
/// On success, pops with [true] so the caller knows the profile is now
/// complete and can retry eligibility.
class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({
    super.key,
    required this.userId,
    this.mandatory = false,
    this.learnQuranEntry = false,
    this.onMandatoryComplete,
  });

  final String userId;
  final bool mandatory;
  final bool learnQuranEntry;
  final VoidCallback? onMandatoryComplete;

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  late final TilawaFormValidationController _validationController;

  @override
  void initState() {
    super.initState();
    _validationController = TilawaFormValidationController();
    context.read<ProfileCompletionBloc>().add(
      ProfileLoadRequested(userId: widget.userId),
    );
  }

  @override
  void dispose() {
    _validationController.dispose();
    super.dispose();
  }

  bool _shouldScrollToValidationError(
    ProfileCompletionState previous,
    ProfileCompletionState current,
  ) {
    if (current is! ProfileCompletionEditing) {
      return false;
    }
    if (previous is! ProfileCompletionEditing) {
      return current.submitValidationAttempt > 0;
    }
    return current.submitValidationAttempt > previous.submitValidationAttempt;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return PopScope(
      canPop: !widget.mandatory,
      child: QuranSessionsScaffold(
        title: l10n.profileCompletionTitle,
        leading: widget.mandatory ? const SizedBox.shrink() : null,
        resizeToAvoidBottomInset: true,
        body: BlocConsumer<ProfileCompletionBloc, ProfileCompletionState>(
          listenWhen:
              (ProfileCompletionState prev, ProfileCompletionState next) {
                if (_shouldScrollToValidationError(prev, next)) {
                  return true;
                }
                return prev != next &&
                    (next is ProfileCompletionSaved ||
                        next is ProfileCompletionFailure);
              },
          listener: (context, state) {
            if (state is ProfileCompletionEditing &&
                state.submitValidationAttempt > 0 &&
                !state.canSubmit) {
              final loc = context.quranSessionsL10n;
              unawaited(
                _validationController.handleValidationFailure(
                  context,
                  TilawaFormValidationResult(
                    issues: state.validationIssues(
                      loc,
                      (failure) => failure.toLocalizedMessage(context),
                    ),
                  ),
                ),
              );
              return;
            }
            if (state is ProfileCompletionSaved) {
              TilawaFeedback.showToast(
                context,
                message: l10n.profileCompletionSavedSuccess,
                variant: TilawaFeedbackVariant.success,
              );
              if (widget.mandatory) {
                widget.onMandatoryComplete?.call();
              } else {
                Navigator.of(context).pop(true);
              }
            }
            if (state is ProfileCompletionFailure) {
              TilawaFeedback.showToast(
                context,
                message: state.failure.toLocalizedMessage(context),
                variant: TilawaFeedbackVariant.error,
              );
            }
          },
          builder: (context, state) => switch (state) {
            ProfileCompletionInitial() ||
            ProfileCompletionLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ProfileCompletionSaving() => _SavingIndicator(
              message: l10n.profileCompletionSaving,
            ),
            ProfileCompletionSaved() => const SizedBox.shrink(),
            ProfileCompletionFailure(:final failure) => _LoadFailureView(
              message: failure.toLocalizedMessage(context),
              retryLabel: l10n.retry,
              onRetry: () => context.read<ProfileCompletionBloc>().add(
                ProfileLoadRequested(userId: widget.userId),
              ),
            ),
            ProfileCompletionEditing(
              :final userId,
              :final availableCountries,
              :final minimumStudentAgeYears,
              :final selectedGender,
              :final selectedDateOfBirth,
              :final selectedCountry,
              :final selectedCity,
              :final availableCities,
              :final isLoadingCities,
              :final countryPickerLocked,
              :final cityPickerLocked,
              :final submitAttempted,
              :final invalidFieldCount,
              :final selectedLearningGoals,
            ) =>
              TilawaFormScreenScaffold(
                validationController: _validationController,
                body: _ProfileCompletionFormBody(
                  l10n: l10n,
                  subtitle: widget.learnQuranEntry
                      ? l10n.profileCompletionLearnQuranSubtitle
                      : l10n.profileCompletionSubtitle,
                  selectedGender: selectedGender,
                  selectedDateOfBirth: selectedDateOfBirth,
                  minimumStudentAgeYears: minimumStudentAgeYears,
                  dateOfBirthError: state.visibleDateOfBirthError(
                    l10n,
                    (failure) => failure.toLocalizedMessage(context),
                  ),
                  genderError: state.genderErrorFor(l10n),
                  countryError: state.countryErrorFor(l10n),
                  cityError: state.cityErrorFor(l10n),
                  availableCountries: availableCountries,
                  selectedCountry: selectedCountry,
                  countryPickerLocked: countryPickerLocked,
                  availableCities: availableCities,
                  selectedCity: selectedCity,
                  isLoadingCities: isLoadingCities,
                  cityPickerLocked: cityPickerLocked,
                  selectedLearningGoals: selectedLearningGoals,
                  onGenderSelected: (gender) => context
                      .read<ProfileCompletionBloc>()
                      .add(GenderSelected(gender)),
                  onDateOfBirthSet: (date) => context
                      .read<ProfileCompletionBloc>()
                      .add(DateOfBirthSet(date)),
                  onCountrySelected: (country) => context
                      .read<ProfileCompletionBloc>()
                      .add(CountrySelected(country)),
                  onCitySelected: (city) => context
                      .read<ProfileCompletionBloc>()
                      .add(CitySelected(city)),
                  onLearningGoalToggled: (goal) => context
                      .read<ProfileCompletionBloc>()
                      .add(LearningGoalToggled(goal)),
                ),
                footer: TilawaFormSubmitFooter(
                  buttonText: l10n.profileCompletionSaveAndContinue,
                  invalidFieldCount: submitAttempted ? invalidFieldCount : null,
                  onPressed: () => context.read<ProfileCompletionBloc>().add(
                    ProfileSubmitted(userId: userId),
                  ),
                ),
              ),
          },
        ),
      ),
    );
  }
}

class _SavingIndicator extends StatelessWidget {
  const _SavingIndicator({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: tokens.spaceMedium),
          Text(message),
        ],
      ),
    );
  }
}

class _LoadFailureView extends StatelessWidget {
  const _LoadFailureView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          SizedBox(height: tokens.spaceMedium),
          TilawaButton(
            text: retryLabel,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _ProfileCompletionFormBody extends StatelessWidget {
  const _ProfileCompletionFormBody({
    required this.l10n,
    required this.subtitle,
    required this.selectedGender,
    required this.selectedDateOfBirth,
    required this.minimumStudentAgeYears,
    required this.dateOfBirthError,
    required this.genderError,
    required this.countryError,
    required this.cityError,
    required this.availableCountries,
    required this.selectedCountry,
    required this.countryPickerLocked,
    required this.availableCities,
    required this.selectedCity,
    required this.isLoadingCities,
    required this.cityPickerLocked,
    required this.selectedLearningGoals,
    required this.onGenderSelected,
    required this.onDateOfBirthSet,
    required this.onCountrySelected,
    required this.onCitySelected,
    required this.onLearningGoalToggled,
  });

  final QuranSessionsLocalizations l10n;
  final String subtitle;
  final UserGender? selectedGender;
  final DateTime? selectedDateOfBirth;
  final int minimumStudentAgeYears;
  final String? dateOfBirthError;
  final String? genderError;
  final String? countryError;
  final String? cityError;
  final List<MarketCountry> availableCountries;
  final MarketCountry? selectedCountry;
  final bool countryPickerLocked;
  final List<MarketCity> availableCities;
  final MarketCity? selectedCity;
  final bool isLoadingCities;
  final bool cityPickerLocked;
  final List<StudentLearningGoal> selectedLearningGoals;
  final ValueChanged<UserGender> onGenderSelected;
  final ValueChanged<DateTime> onDateOfBirthSet;
  final ValueChanged<MarketCountry> onCountrySelected;
  final ValueChanged<MarketCity> onCitySelected;
  final ValueChanged<StudentLearningGoal> onLearningGoalToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilawaStateVisual(
          icon: Icons.person_outline_rounded,
          size: tokens.iconSizeExtraLarge + tokens.spaceExtraLarge,
        ),
        SizedBox(height: tokens.spaceLarge),
        Text(
          l10n.profileCompletionHeadline,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceExtraLarge + tokens.spaceSmall),
        TilawaFormFieldAnchor(
          fieldId: ProfileCompletionFieldIds.gender,
          semanticLabel: l10n.profileFieldGender,
          order: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileFieldGender,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: tokens.spaceSmall),
              _GenderPicker(
                maleLabel: l10n.gender_male,
                femaleLabel: l10n.gender_female,
                selected: selectedGender,
                onChanged: onGenderSelected,
              ),
              TilawaFormSectionError(errorText: genderError),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        TilawaFormFieldAnchor(
          fieldId: ProfileCompletionFieldIds.dateOfBirth,
          semanticLabel: l10n.profileFieldDateOfBirth,
          order: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileFieldDateOfBirth,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: tokens.spaceSmall),
              _DateOfBirthField(
                selected: selectedDateOfBirth,
                minimumAgeYears: minimumStudentAgeYears,
                errorText: dateOfBirthError,
                fieldLabel: l10n.profileFieldDateOfBirth,
                placeholder: l10n.profileCompletionSelectDateOfBirth,
                onChanged: onDateOfBirthSet,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        TilawaFormFieldAnchor(
          fieldId: ProfileCompletionFieldIds.country,
          semanticLabel: l10n.profileFieldCountry,
          order: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileFieldCountry,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: tokens.spaceSmall),
              _CountryPicker(
                countries: availableCountries,
                selected: selectedCountry,
                readOnly: countryPickerLocked,
                errorText: countryError,
                fieldLabel: l10n.profileFieldCountry,
                placeholder: l10n.profileCompletionSelectCountry,
                onChanged: onCountrySelected,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        TilawaFormFieldAnchor(
          fieldId: ProfileCompletionFieldIds.city,
          semanticLabel: l10n.profileFieldCity,
          order: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileFieldCity,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: tokens.spaceSmall),
              _CityPicker(
                cities: availableCities,
                selected: selectedCity,
                countrySelected: selectedCountry != null,
                isLoading: isLoadingCities,
                readOnly: cityPickerLocked,
                errorText: cityError,
                fieldLabel: l10n.profileFieldCity,
                loadingHint: l10n.profileCompletionLoadingCities,
                selectCityHint: l10n.profileCompletionSelectCity,
                selectCountryFirstHint:
                    l10n.profileCompletionSelectCountryFirst,
                onChanged: onCitySelected,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceExtraLarge),
        TilawaFormFieldAnchor(
          fieldId: ProfileCompletionFieldIds.learningGoals,
          semanticLabel: l10n.profileFieldLearningGoals,
          order: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileFieldLearningGoals,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                l10n.profileLearningGoalsHelper,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              Wrap(
                spacing: tokens.spaceSmall,
                runSpacing: tokens.spaceSmall,
                children: [
                  for (final goal in kStudentLearningGoalOptions)
                    TilawaSelectionPill(
                      label: l10n.specializationLabel(goal.name),
                      selected: selectedLearningGoals.contains(goal),
                      onTap: () => onLearningGoalToggled(goal),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Gender picker ─────────────────────────────────────────────────────────────

class _GenderPicker extends StatelessWidget {
  const _GenderPicker({
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
    final tokens = Theme.of(context).tokens;

    return Row(
      children: [
        Expanded(
          child: _GenderOption(
            label: maleLabel,
            icon: Icons.male_rounded,
            gender: UserGender.male,
            isSelected: selected == UserGender.male,
            onTap: () => onChanged(UserGender.male),
          ),
        ),
        SizedBox(width: tokens.spaceMedium),
        Expanded(
          child: _GenderOption(
            label: femaleLabel,
            icon: Icons.female_rounded,
            gender: UserGender.female,
            isSelected: selected == UserGender.female,
            onTap: () => onChanged(UserGender.female),
          ),
        ),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.icon,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final UserGender gender;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final radius = tokens.resolveRadius(family: TilawaRadiusFamily.chrome);

    return TilawaInteractiveSurface(
      onTap: onTap,
      selected: isSelected,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedContainer(
        duration: theme.componentTokens.immersiveComposer.transitionDuration,
        constraints: BoxConstraints(minHeight: tokens.minInteractiveDimension),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isSelected ? scheme.primary : Colors.transparent,
            width: theme.componentTokens.card.borderWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceLarge),
          child: Column(
            children: [
              Icon(
                icon,
                size: tokens.iconSizeLarge,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              SizedBox(height: tokens.spaceSmall),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date of birth field ───────────────────────────────────────────────────────

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.selected,
    required this.minimumAgeYears,
    required this.onChanged,
    required this.fieldLabel,
    required this.placeholder,
    this.errorText,
  });

  final DateTime? selected;
  final int minimumAgeYears;
  final ValueChanged<DateTime> onChanged;
  final String fieldLabel;
  final String placeholder;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMMd(locale);
    final hasValue = selected != null;

    return TilawaReadOnlyField(
      prefixIcon: Icons.calendar_today_outlined,
      errorText: errorText,
      semanticLabel: fieldLabel,
      onTap: () async {
        final firstDate = DobValidator.earliest;
        final lastDate = DobValidator.latestBirthDate(
          minimumAgeYears: minimumAgeYears,
        );
        var initialDate = selected ?? lastDate;
        if (initialDate.isAfter(lastDate)) initialDate = lastDate;
        if (initialDate.isBefore(firstDate)) initialDate = firstDate;
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: placeholder,
        );
        if (picked != null) onChanged(picked);
      },
      child: Text(
        hasValue ? dateFmt.format(selected!) : placeholder,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Country picker ────────────────────────────────────────────────────────────

class _CountryPicker extends StatelessWidget {
  const _CountryPicker({
    required this.countries,
    required this.selected,
    required this.onChanged,
    required this.fieldLabel,
    required this.placeholder,
    this.readOnly = false,
    this.errorText,
  });

  final List<MarketCountry> countries;
  final MarketCountry? selected;
  final ValueChanged<MarketCountry> onChanged;
  final String fieldLabel;
  final String placeholder;
  final bool readOnly;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final label = selected == null ? placeholder : _countryLabel(selected!);

    if (readOnly && selected != null) {
      return TilawaDropdownField<MarketCountry>(
        value: selected,
        hintText: label,
        semanticLabel: fieldLabel,
        prefixIcon: Icons.public_outlined,
        enabled: false,
        errorText: errorText,
        items: [
          TilawaDropdownItem(value: selected!, label: label),
        ],
        onChanged: null,
      );
    }

    return TilawaDropdownField<MarketCountry>(
      value: selected,
      hintText: placeholder,
      semanticLabel: fieldLabel,
      prefixIcon: Icons.public_outlined,
      errorText: errorText,
      items: [
        for (final country in countries)
          TilawaDropdownItem(
            value: country,
            label: _countryLabel(country),
          ),
      ],
      onChanged: onChanged,
    );
  }

  String _countryLabel(MarketCountry country) {
    final flag = country.flagEmoji;
    if (flag == null || flag.isEmpty) return country.countryName;
    return '$flag ${country.countryName}';
  }
}

class _CityPicker extends StatelessWidget {
  const _CityPicker({
    required this.cities,
    required this.selected,
    required this.countrySelected,
    required this.onChanged,
    required this.fieldLabel,
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
  final String fieldLabel;
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
        semanticLabel: fieldLabel,
        prefixIcon: Icons.location_city_outlined,
        enabled: false,
        items: const [],
        onChanged: null,
      );
    }

    if (readOnly && selected != null) {
      return TilawaDropdownField<MarketCity>(
        value: selected,
        hintText: selected!.cityName,
        semanticLabel: fieldLabel,
        prefixIcon: Icons.location_city_outlined,
        enabled: false,
        errorText: errorText,
        items: [
          TilawaDropdownItem(value: selected!, label: selected!.cityName),
        ],
        onChanged: null,
      );
    }

    return TilawaDropdownField<MarketCity>(
      value: selected,
      hintText: countrySelected ? selectCityHint : selectCountryFirstHint,
      semanticLabel: fieldLabel,
      prefixIcon: Icons.location_city_outlined,
      enabled: countrySelected,
      errorText: errorText,
      items: [
        for (final city in cities)
          TilawaDropdownItem(value: city, label: city.cityName),
      ],
      onChanged: countrySelected ? onChanged : null,
    );
  }
}
