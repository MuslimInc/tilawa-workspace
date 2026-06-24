import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_profile.dart';
import '../../domain/usecases/get_current_user_teacher_capability_usecase.dart';
import '../../domain/usecases/update_teacher_meeting_link_usecase.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';

/// Lets verified teachers set the external meeting URL students use to join.
class TeacherExternalMeetingUrlCard extends StatefulWidget {
  const TeacherExternalMeetingUrlCard({
    super.key,
    required this.userId,
    required this.getCapability,
    required this.updateMeetingLink,
  });

  final String userId;
  final GetCurrentUserTeacherCapabilityUseCase getCapability;
  final UpdateTeacherMeetingLinkUseCase updateMeetingLink;

  @override
  State<TeacherExternalMeetingUrlCard> createState() =>
      _TeacherExternalMeetingUrlCardState();
}

class _TeacherExternalMeetingUrlCardState
    extends State<TeacherExternalMeetingUrlCard> {
  final _meetingUrlCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  TeacherProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _meetingUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.getCapability(widget.userId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loading = false),
      (capability) {
        final profile = capability.profile;
        if (profile != null &&
            _meetingUrlCtrl.text.isEmpty &&
            (profile.externalMeetingUrl?.isNotEmpty ?? false)) {
          _meetingUrlCtrl.text = profile.externalMeetingUrl!;
        }
        setState(() {
          _loading = false;
          _profile = profile;
        });
      },
    );
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) return;

    setState(() => _saving = true);
    final result = await widget.updateMeetingLink(
      userId: widget.userId,
      externalMeetingUrl: _meetingUrlCtrl.text,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _saving = false);
        TilawaFeedback.showToast(
          context,
          message: failure.toLocalizedMessage(context),
          variant: TilawaFeedbackVariant.error,
        );
      },
      (updated) {
        setState(() {
          _saving = false;
          _profile = updated;
        });
        TilawaFeedback.showToast(
          context,
          message: context.quranSessionsL10n.teacherExternalMeetingUrlSaved,
          variant: TilawaFeedbackVariant.success,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _profile == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceLarge),
      child: TilawaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teacherExternalMeetingUrlLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: tokens.spaceSmall),
            TilawaTextField(
              controller: _meetingUrlCtrl,
              label: l10n.teacherExternalMeetingUrlLabel,
              hintText: l10n.teacherExternalMeetingUrlHint,
              helperText: l10n.teacherExternalMeetingUrlHelper,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: tokens.spaceMedium),
            TilawaButton(
              text: l10n.teacherExternalMeetingUrlSave,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
              size: TilawaButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }
}
