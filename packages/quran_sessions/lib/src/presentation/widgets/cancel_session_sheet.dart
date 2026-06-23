import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom sheet collecting a mandatory cancellation reason and policy copy.
Future<String?> showCancelSessionSheet(
  BuildContext context, {
  required DateTime sessionStartsAt,
  required SessionPricingType pricingType,
  ConfigurableCancellationPolicy? policy,
}) {
  final l10n = context.quranSessionsL10n;
  final cancellationPolicy = policy ?? const ConfigurableCancellationPolicy();
  final policyKey = cancellationPolicy.describe(
    actor: ActorRole.student,
    sessionStartsAt: sessionStartsAt,
    pricingType: pricingType,
  );
  final policyMessage = _policyMessage(l10n, policyKey);

  return showTilawaModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => _CancelSessionSheetBody(policyMessage: policyMessage),
  );
}

String _policyMessage(dynamic l10n, String key) {
  return switch (key) {
    'cancellation_blocked_within_notice' => l10n.cancelPolicyBlockedNotice,
    'cancellation_free_no_refund' => l10n.cancelPolicyFree,
    'cancellation_full_refund' => l10n.cancelPolicyFullRefund,
    'cancellation_partial_refund' => l10n.cancelPolicyPartialRefund,
    _ => l10n.cancelPolicyNoRefund,
  };
}

class _CancelSessionSheetBody extends StatefulWidget {
  const _CancelSessionSheetBody({required this.policyMessage});

  final String policyMessage;

  @override
  State<_CancelSessionSheetBody> createState() =>
      _CancelSessionSheetBodyState();
}

class _CancelSessionSheetBodyState extends State<_CancelSessionSheetBody> {
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
          title: l10n.cancelSessionDialogTitle,
        ),
        footer: TilawaBottomSheetActions(
          primaryLabel: l10n.keepSession,
          onPrimary: () => Navigator.pop(context),
          secondaryLabel: l10n.cancelSessionAction,
          onSecondary: _submit,
          secondaryVariant: TilawaButtonVariant.dangerOutline,
        ),
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.policyMessage),
                  SizedBox(height: tokens.spaceLarge),
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.cancelReasonLabel,
                      hintText: l10n.cancelReasonHint,
                      errorText: _error,
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
    final reason = _controller.text.trim();
    if (reason.length < 3) {
      setState(() => _error = context.quranSessionsL10n.cancelReasonRequired);
      return;
    }
    Navigator.pop(context, reason);
  }
}
