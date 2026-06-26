import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Max tutor rejection reason length (client validation; CF stores trimmed text).
const tutorRejectBookingReasonMaxLength = 280;

/// Outcome when tutor confirms rejection; [reason] null when omitted.
class TutorRejectBookingSheetResult {
  const TutorRejectBookingSheetResult({this.reason});

  final String? reason;
}

/// Bottom sheet for tutor to optionally explain a booking rejection.
Future<TutorRejectBookingSheetResult?> showTutorRejectBookingSheet(
  BuildContext context,
) {
  return showTilawaModalBottomSheet<TutorRejectBookingSheetResult>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => const _TutorRejectBookingSheetBody(),
  );
}

class _TutorRejectBookingSheetBody extends StatefulWidget {
  const _TutorRejectBookingSheetBody();

  @override
  State<_TutorRejectBookingSheetBody> createState() =>
      _TutorRejectBookingSheetBodyState();
}

class _TutorRejectBookingSheetBodyState
    extends State<_TutorRejectBookingSheetBody> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: TilawaBottomSheetScaffold(
        topBar: TilawaBottomSheetTitleRow(
          title: l10n.tutorRejectBookingSheetTitle,
        ),
        footer: TilawaBottomSheetActions(
          primaryLabel: l10n.tutorRejectBookingConfirmAction,
          onPrimary: _submit,
          primaryVariant: TilawaButtonVariant.danger,
          secondaryLabel: l10n.tutorRejectBookingGoBack,
          onSecondary: () => Navigator.pop(context),
        ),
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.tutorRejectBookingSheetBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    maxLength: tutorRejectBookingReasonMaxLength,
                    decoration: InputDecoration(
                      labelText: l10n.tutorRejectBookingReasonLabel,
                      hintText: l10n.tutorRejectBookingReasonHint,
                      errorText: _error,
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.length > tutorRejectBookingReasonMaxLength) {
      setState(
        () =>
            _error = context.quranSessionsL10n.tutorRejectBookingReasonTooLong,
      );
      return;
    }
    Navigator.pop(
      context,
      TutorRejectBookingSheetResult(
        reason: trimmed.isEmpty ? null : trimmed,
      ),
    );
  }
}
