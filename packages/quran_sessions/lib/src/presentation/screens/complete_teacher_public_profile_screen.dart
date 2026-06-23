import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_profile.dart';
import '../../domain/usecases/get_current_user_teacher_capability_usecase.dart';
import '../../domain/usecases/save_teacher_public_profile_usecase.dart';
import '../../domain/value_objects/teacher_public_name.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../forms/teacher_application_validation_l10n.dart';

/// Collects required public teacher profile fields before dashboard access.
class CompleteTeacherPublicProfileScreen extends StatefulWidget {
  const CompleteTeacherPublicProfileScreen({
    super.key,
    required this.userId,
    required this.getCapability,
    required this.saveProfile,
    this.onComplete,
  });

  final String userId;
  final GetCurrentUserTeacherCapabilityUseCase getCapability;
  final SaveTeacherPublicProfileUseCase saveProfile;
  final VoidCallback? onComplete;

  @override
  State<CompleteTeacherPublicProfileScreen> createState() =>
      _CompleteTeacherPublicProfileScreenState();
}

class _CompleteTeacherPublicProfileScreenState
    extends State<CompleteTeacherPublicProfileScreen> {
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

  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _languages = <String>{};
  final _specializations = <String>{};

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _displayNameError;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final result = await widget.getCapability(widget.userId);
    if (!mounted) return;

    result.fold(
      (_) => setState(() => _loading = false),
      (capability) {
        final profile = capability.profile;
        if (profile != null) {
          _seedFromProfile(profile);
        }
        setState(() => _loading = false);
      },
    );
  }

  void _seedFromProfile(TeacherProfile profile) {
    if (_displayNameCtrl.text.isEmpty && profile.displayName.isNotEmpty) {
      _displayNameCtrl.text = profile.displayName;
    }
    if (_bioCtrl.text.isEmpty && (profile.publicBio?.isNotEmpty ?? false)) {
      _bioCtrl.text = profile.publicBio!;
    }
    _languages
      ..clear()
      ..addAll(profile.teachingLanguages);
    _specializations
      ..clear()
      ..addAll(profile.specializations);
  }

  Future<void> _save() async {
    final l10n = context.quranSessionsL10n;
    final nameFailure = ValidateTeacherPublicName.failureFor(
      _displayNameCtrl.text,
    );
    if (nameFailure != null) {
      setState(
        () => _displayNameError = l10n.messageForPublicNameFailure(nameFailure),
      );
    } else {
      setState(() => _displayNameError = null);
    }

    if (_displayNameCtrl.text.trim().isEmpty ||
        _bioCtrl.text.trim().isEmpty ||
        _languages.isEmpty ||
        _specializations.isEmpty ||
        nameFailure != null) {
      TilawaFeedback.showToast(
        context,
        message: l10n.teacherProfileIncomplete,
        variant: TilawaFeedbackVariant.error,
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.saveProfile(
      userId: widget.userId,
      displayName: _displayNameCtrl.text,
      publicBio: _bioCtrl.text,
      teachingLanguages: _languages.toList(),
      specializations: _specializations.toList(),
    );

    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          _saving = false;
          _error = failure.toLocalizedMessage(context);
        });
      },
      (profile) async {
        final capabilityResult = await widget.getCapability(widget.userId);
        if (!mounted) return;

        setState(() => _saving = false);
        final canOpenDashboard = capabilityResult.fold(
          (_) => false,
          (capability) => capability.canAccessTeacherDashboard,
        );
        if (canOpenDashboard) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.completeTeacherProfileTitle)),
      resizeToAvoidBottomInset: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TilawaFormScreenScaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.completeTeacherProfileSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: tokens.spaceMedium),
                  Container(
                    padding: EdgeInsets.all(tokens.spaceMedium),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    ),
                    child: Text(
                      l10n.teacherProfileHiddenUntilComplete,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  TilawaTextField(
                    controller: _displayNameCtrl,
                    label: l10n.teacherPublicNameLabel,
                    hintText: l10n.visibleToStudents,
                    helperText: l10n.teacherPublicNameHelper,
                    errorText: _displayNameError,
                    onChanged: (_) {
                      if (_displayNameError != null) {
                        setState(() => _displayNameError = null);
                      }
                    },
                  ),
                  SizedBox(height: tokens.spaceMedium),
                  TilawaTextField(
                    controller: _bioCtrl,
                    label: l10n.bioSectionTitle,
                    hintText: l10n.bioHint,
                    maxLines: 4,
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  Text(l10n.teachingLanguagesSelect),
                  SizedBox(height: tokens.spaceSmall),
                  Wrap(
                    spacing: tokens.spaceSmall,
                    runSpacing: tokens.spaceSmall,
                    children: _availableLanguages.map((code) {
                      final selected = _languages.contains(code);
                      return TilawaSelectionPill(
                        label: l10n.teachingLanguageLabel(code),
                        selected: selected,
                        onTap: () => setState(() {
                          if (selected) {
                            _languages.remove(code);
                          } else {
                            _languages.add(code);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  Text(l10n.specializationsSelect),
                  SizedBox(height: tokens.spaceSmall),
                  Wrap(
                    spacing: tokens.spaceSmall,
                    runSpacing: tokens.spaceSmall,
                    children: _availableSpecializations.map((code) {
                      final selected = _specializations.contains(code);
                      return TilawaSelectionPill(
                        label: l10n.specializationLabel(code),
                        selected: selected,
                        onTap: () => setState(() {
                          if (selected) {
                            _specializations.remove(code);
                          } else {
                            _specializations.add(code);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: tokens.spaceMedium),
                    Text(
                      _error!,
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                ],
              ),
              footer: TilawaButton(
                text: l10n.completeTeacherProfile,
                isFullWidth: true,
                isLoading: _saving,
                size: TilawaButtonSize.large,
                onPressed: _saving ? null : _save,
              ),
            ),
    );
  }
}
