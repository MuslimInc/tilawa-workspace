import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';

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

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _CancelSessionSheetBody(policyMessage: policyMessage),
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.cancelSessionDialogTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(widget.policyMessage),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.keepSession),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.cancelSessionAction),
                ),
              ),
            ],
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
