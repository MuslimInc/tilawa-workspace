import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_application.dart';
import '../../utils/phone_normalizer.dart';
import '../blocs/teacher_application/teacher_application_bloc.dart';
import '../blocs/teacher_application/teacher_application_event.dart';
import '../blocs/teacher_application/teacher_application_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../forms/teacher_application_field_ids.dart';
import '../forms/teacher_application_validation_l10n.dart';
import '../widgets/quran_sessions_scaffold.dart';

/// Form screen for filling a teacher application (draft → pending).
///
/// Fields: phone, country code, contact method, teaching languages,
/// specializations, bio.
///
/// [onSubmitted] is called when the application reaches `pending` status.
class TeacherApplicationScreen extends StatefulWidget {
  const TeacherApplicationScreen({
    super.key,
    required this.userId,
    required this.onSubmitted,
  });

  final String userId;
  final VoidCallback onSubmitted;

  @override
  State<TeacherApplicationScreen> createState() =>
      _TeacherApplicationScreenState();
}

class _TeacherApplicationScreenState extends State<TeacherApplicationScreen> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _publicNameCtrl;
  late final TextEditingController _bioCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController();
    _publicNameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    context.read<TeacherApplicationBloc>().add(
      TeacherApplicationLoadRequested(userId: widget.userId),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _publicNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(TeacherApplicationEditing state) {
    if (!_initialized) {
      _initialized = true;
      if (_phoneCtrl.text != state.phoneRaw) {
        _phoneCtrl.text = state.phoneRaw;
      }
      final seedName = state.publicDisplayNameRaw.isNotEmpty
          ? state.publicDisplayNameRaw
          : (state.application.publicDisplayName ??
                state.prefillPublicDisplayName ??
                '');
      if (_publicNameCtrl.text != seedName) {
        _publicNameCtrl.text = seedName;
      }
      if (_bioCtrl.text != (state.application.bio ?? '')) {
        _bioCtrl.text = state.application.bio ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return QuranSessionsScaffold(
      title: l10n.teacherApplicationTitle,
      body: BlocConsumer<TeacherApplicationBloc, TeacherApplicationState>(
        listener: (context, state) {
          if (state is TeacherApplicationStatusLoaded &&
              state.application.isPending) {
            widget.onSubmitted();
          }
          if (state is TeacherApplicationFailureState) {
            TilawaFeedback.showToast(
              context,
              message: state.failure.toLocalizedMessage(context),
              variant: TilawaFeedbackVariant.error,
            );
            // Restore the previous state so the user can correct input.
            context.read<TeacherApplicationBloc>()
            // ignore: invalid_use_of_visible_for_testing_member
            .emit(state.previousState);
          }
        },
        builder: (context, state) => switch (state) {
          TeacherApplicationInitial() ||
          TeacherApplicationLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          TeacherApplicationNotStarted(:final userId) => _NotStartedView(
            onStart: () => context.read<TeacherApplicationBloc>().add(
              TeacherApplicationStartRequested(userId: userId),
            ),
          ),
          TeacherApplicationSubmitting() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.submittingApplication),
              ],
            ),
          ),
          TeacherApplicationEditing() => _FormBody(
            state: state,
            phoneController: _phoneCtrl,
            publicNameController: _publicNameCtrl,
            bioController: _bioCtrl,
            onInit: _syncControllers,
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

// ── Not started view ──────────────────────────────────────────────────────────

class _NotStartedView extends StatelessWidget {
  const _NotStartedView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: scheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.becomeTeacherOnTilawa,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.becomeTeacherApplicationIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TilawaButton(
            text: l10n.startApplication,
            leadingIcon: const Icon(Icons.arrow_forward),
            onPressed: onStart,
            isFullWidth: true,
            size: TilawaButtonSize.large,
          ),
        ],
      ),
    );
  }
}

// ── Form body ─────────────────────────────────────────────────────────────────

class _FormBody extends StatefulWidget {
  const _FormBody({
    required this.state,
    required this.phoneController,
    required this.publicNameController,
    required this.bioController,
    required this.onInit,
  });

  final TeacherApplicationEditing state;
  final TextEditingController phoneController;
  final TextEditingController publicNameController;
  final TextEditingController bioController;
  final void Function(TeacherApplicationEditing) onInit;

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  late final TilawaFormValidationController _validationController;
  late final FocusNode _publicNameFocusNode;
  late final FocusNode _phoneFocusNode;
  late final FocusNode _bioFocusNode;

  @override
  void initState() {
    super.initState();
    _validationController = TilawaFormValidationController();
    _publicNameFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _bioFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _validationController.dispose();
    _publicNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  bool _shouldScrollToValidationError(
    TeacherApplicationState previous,
    TeacherApplicationState current,
  ) {
    if (current is! TeacherApplicationEditing) {
      return false;
    }
    if (previous is! TeacherApplicationEditing) {
      return current.submitValidationAttempt > 0;
    }
    return current.submitValidationAttempt > previous.submitValidationAttempt;
  }

  @override
  Widget build(BuildContext context) {
    widget.onInit(widget.state);
    final bloc = context.read<TeacherApplicationBloc>();

    return BlocListener<TeacherApplicationBloc, TeacherApplicationState>(
      listenWhen: _shouldScrollToValidationError,
      listener: (context, state) {
        if (state is! TeacherApplicationEditing || state.canSubmit) {
          return;
        }
        final l10n = context.quranSessionsL10n;
        unawaited(
          _validationController.handleValidationFailure(
            context,
            TilawaFormValidationResult(
              issues: state.validationIssues
                  .map(
                    (issue) => TilawaFormFieldIssue(
                      fieldId: issue.fieldId,
                      errorMessage:
                          l10n.messageForFieldError(
                            issue.fieldId,
                            issue.errorMessage,
                          ) ??
                          issue.errorMessage,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
      child: _FormContent(
        state: widget.state,
        phoneController: widget.phoneController,
        publicNameController: widget.publicNameController,
        bioController: widget.bioController,
        validationController: _validationController,
        publicNameFocusNode: _publicNameFocusNode,
        phoneFocusNode: _phoneFocusNode,
        bioFocusNode: _bioFocusNode,
        onSubmit: () => bloc.add(const TeacherApplicationSubmitRequested()),
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.state,
    required this.phoneController,
    required this.publicNameController,
    required this.bioController,
    required this.validationController,
    required this.publicNameFocusNode,
    required this.phoneFocusNode,
    required this.bioFocusNode,
    required this.onSubmit,
  });

  final TeacherApplicationEditing state;
  final TextEditingController phoneController;
  final TextEditingController publicNameController;
  final TextEditingController bioController;
  final TilawaFormValidationController validationController;
  final FocusNode publicNameFocusNode;
  final FocusNode phoneFocusNode;
  final FocusNode bioFocusNode;
  final VoidCallback onSubmit;

  static const _availableLanguages = ['ar', 'en', 'ur', 'fr', 'tr', 'ms'];

  static const _availableSpecializations = [
    'tajweed',
    'recitation',
    'hifz',
    'review',
    'children',
    'qaida',
    'tafsir',
    'arabic',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final bloc = context.read<TeacherApplicationBloc>();
    final application = state.application;
    final countryCode = application.phoneCountryCode ?? 'EG';

    String? fieldError(String fieldId, String? code) =>
        l10n.messageForFieldError(fieldId, code);

    return TilawaFormScreenScaffold(
      validationController: validationController,
      bodyPadding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceLarge,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TilawaFormFieldAnchor(
            fieldId: TeacherApplicationFieldIds.publicDisplayName,
            semanticLabel: l10n.teacherPublicNameLabel,
            order: 0,
            focusNode: publicNameFocusNode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle('${l10n.teacherPublicNameLabel} *'),
                SizedBox(height: tokens.spaceExtraSmall),
                Text(
                  l10n.teacherPublicNameHelper,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: tokens.spaceExtraSmall),
                Text(
                  l10n.realNameRequiredForTeachers,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                TilawaTextField(
                  controller: publicNameController,
                  focusNode: publicNameFocusNode,
                  label: l10n.publicTeacherName,
                  hintText: l10n.visibleToStudents,
                  errorText: fieldError(
                    TeacherApplicationFieldIds.publicDisplayName,
                    state.visiblePublicDisplayNameErrorCode,
                  ),
                  onChanged: (value) => bloc.add(
                    TeacherApplicationPublicDisplayNameChanged(value),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          TilawaFormFieldAnchor(
            fieldId: TeacherApplicationFieldIds.phone,
            semanticLabel: l10n.phoneNumber,
            order: 1,
            focusNode: phoneFocusNode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle('${l10n.phoneNumber} *'),
                SizedBox(height: tokens.spaceExtraSmall),
                Text(
                  l10n.phoneNumberRequiredHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CountryCodePicker(
                        selected: countryCode,
                        onChanged: (code) => bloc.add(
                          TeacherApplicationPhoneCountryCodeChanged(code),
                        ),
                      ),
                      SizedBox(width: tokens.spaceSmall),
                      Expanded(
                        child: TilawaTextField(
                          controller: phoneController,
                          focusNode: phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          hintText: PhoneNormalizer.hint(countryCode),
                          errorText: fieldError(
                            TeacherApplicationFieldIds.phone,
                            state.visiblePhoneErrorCode,
                          ),
                          onChanged: (v) => bloc.add(
                            TeacherApplicationPhoneChanged(v.trim()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          _SectionTitle(l10n.preferredContactMethod),
          SizedBox(height: tokens.spaceSmall),
          _ContactMethodPicker(
            selected: application.preferredContactMethod,
            onChanged: (m) =>
                bloc.add(TeacherApplicationContactMethodChanged(m)),
          ),
          SizedBox(height: tokens.spaceLarge),
          TilawaFormFieldAnchor(
            fieldId: TeacherApplicationFieldIds.teachingLanguages,
            semanticLabel: l10n.teachingLanguages,
            order: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(l10n.teachingLanguagesSelect),
                SizedBox(height: tokens.spaceSmall),
                Wrap(
                  spacing: tokens.spaceSmall,
                  runSpacing: tokens.spaceSmall,
                  children: _availableLanguages.map((code) {
                    final selected = application.teachingLanguages.contains(
                      code,
                    );
                    return TilawaSelectionPill(
                      label: l10n.teachingLanguageLabel(code),
                      selected: selected,
                      onTap: () =>
                          bloc.add(TeacherApplicationLanguageToggled(code)),
                    );
                  }).toList(),
                ),
                TilawaFormSectionError(
                  errorText: fieldError(
                    TeacherApplicationFieldIds.teachingLanguages,
                    state.visibleTeachingLanguagesErrorCode,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          TilawaFormFieldAnchor(
            fieldId: TeacherApplicationFieldIds.specializations,
            semanticLabel: l10n.specializations,
            order: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(l10n.specializationsSelect),
                SizedBox(height: tokens.spaceSmall),
                Wrap(
                  spacing: tokens.spaceSmall,
                  runSpacing: tokens.spaceSmall,
                  children: _availableSpecializations.map((code) {
                    final selected = application.specializations.contains(code);
                    return TilawaSelectionPill(
                      label: l10n.specializationLabel(code),
                      selected: selected,
                      onTap: () => bloc.add(
                        TeacherApplicationSpecializationToggled(code),
                      ),
                    );
                  }).toList(),
                ),
                TilawaFormSectionError(
                  errorText: fieldError(
                    TeacherApplicationFieldIds.specializations,
                    state.visibleSpecializationsErrorCode,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          TilawaFormFieldAnchor(
            fieldId: TeacherApplicationFieldIds.bio,
            semanticLabel: l10n.bio,
            order: 4,
            focusNode: bioFocusNode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(l10n.bioSectionTitle),
                SizedBox(height: tokens.spaceSmall),
                TilawaTextField(
                  controller: bioController,
                  focusNode: bioFocusNode,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 500,
                  textAlignVertical: TextAlignVertical.top,
                  hintText: l10n.bioHint,
                  errorText: fieldError(
                    TeacherApplicationFieldIds.bio,
                    state.visibleBioErrorCode,
                  ),
                  onChanged: (v) => bloc.add(TeacherApplicationBioChanged(v)),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: TilawaFormSubmitFooter(
        buttonText: l10n.submitApplicationForReview,
        invalidFieldCount: state.submitAttempted
            ? state.invalidFieldCount
            : null,
        isLoading: state.isSaving,
        onPressed: onSubmit,
      ),
    );
  }
}

// ── Country code picker ───────────────────────────────────────────────────────

class _CountryCodePicker extends StatelessWidget {
  const _CountryCodePicker({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('SA', '🇸🇦 +966'),
    ('EG', '🇪🇬 +20'),
    ('AE', '🇦🇪 +971'),
    ('KW', '🇰🇼 +965'),
    ('QA', '🇶🇦 +974'),
    ('BH', '🇧🇭 +973'),
    ('OM', '🇴🇲 +968'),
    ('JO', '🇯🇴 +962'),
    ('GB', '🇬🇧 +44'),
    ('US', '🇺🇸 +1'),
    ('CA', '🇨🇦 +1'),
    ('PK', '🇵🇰 +92'),
    ('IN', '🇮🇳 +91'),
    ('MY', '🇲🇾 +60'),
    ('TR', '🇹🇷 +90'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return TilawaDropdownField<String>(
      value: selected,
      semanticLabel: l10n.countryCode,
      shrinkWrapWidth: true,
      items: [
        for (final e in _options) TilawaDropdownItem(value: e.$1, label: e.$2),
      ],
      onChanged: onChanged,
    );
  }
}

// ── Contact method picker ─────────────────────────────────────────────────────

class _ContactMethodPicker extends StatelessWidget {
  const _ContactMethodPicker({required this.selected, required this.onChanged});

  final PreferredContactMethod? selected;
  final ValueChanged<PreferredContactMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return Wrap(
      spacing: 8,
      children: PreferredContactMethod.values.map((m) {
        return TilawaSelectionPill(
          label: l10n.preferredContactMethodLabel(m),
          selected: selected == m,
          onTap: () => onChanged(m),
        );
      }).toList(),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
}
