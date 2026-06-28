import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/usecases/approve_child_guardian_booking_usecase.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/quran_sessions_scaffold.dart';

/// Guardian signs in and records consent for a child student's bookings.
class GuardianApprovalCaptureScreen extends StatefulWidget {
  const GuardianApprovalCaptureScreen({
    super.key,
    required this.studentId,
    required this.approveChildGuardianBooking,
    this.onApproved,
  });

  final String studentId;
  final ApproveChildGuardianBookingUseCase approveChildGuardianBooking;
  final VoidCallback? onApproved;

  @override
  State<GuardianApprovalCaptureScreen> createState() =>
      _GuardianApprovalCaptureScreenState();
}

class _GuardianApprovalCaptureScreenState
    extends State<GuardianApprovalCaptureScreen> {
  late final TextEditingController _studentIdController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _studentIdController = TextEditingController(text: widget.studentId);
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty || _submitting) {
      return;
    }

    setState(() => _submitting = true);
    final result = await widget.approveChildGuardianBooking(
      studentId: studentId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    result.fold(
      (failure) {
        TilawaFeedback.showToast(
          context,
          message: failure.toLocalizedMessage(context),
          variant: TilawaFeedbackVariant.error,
        );
      },
      (_) {
        TilawaFeedback.showToast(
          context,
          message: context.quranSessionsL10n.guardianApprovalCaptured,
          variant: TilawaFeedbackVariant.success,
        );
        widget.onApproved?.call();
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return QuranSessionsScaffold(
      title: l10n.guardianApprovalTitle,
      bottomNavigationBar: TilawaBottomActionArea(
        child: TilawaButton(
          text: l10n.guardianApprovalConfirm,
          onPressed: _submitting ? null : _submit,
          isFullWidth: true,
          size: TilawaButtonSize.large,
          isLoading: _submitting,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TilawaStateVisual(
              icon: Icons.family_restroom_outlined,
              tone: TilawaStateVisualTone.primary,
              size: tokens.iconSizeExtraLarge + tokens.spaceExtraLarge,
            ),
            SizedBox(height: tokens.spaceLarge),
            Text(
              l10n.guardianApprovalBody,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceExtraLarge),
            Text(
              l10n.guardianApprovalStudentIdLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: tokens.spaceSmall),
            TilawaTextField(
              controller: _studentIdController,
              readOnly: widget.studentId.isNotEmpty,
              hintText: l10n.guardianApprovalStudentIdHint,
            ),
          ],
        ),
      ),
    );
  }
}
