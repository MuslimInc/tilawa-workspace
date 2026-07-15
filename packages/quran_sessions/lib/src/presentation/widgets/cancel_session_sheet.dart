import 'package:flutter/material.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom sheet collecting a mandatory cancellation reason and policy copy.
Future<String?> showCancelSessionSheet(
  BuildContext context, {
  required DateTime sessionStartsAt,
  required SessionPricingType pricingType,
  ConfigurableCancellationPolicy? policy,
  bool isManualPayment = false,
}) {
  final l10n = context.quranSessionsL10n;
  final cancellationPolicy = policy ?? const ConfigurableCancellationPolicy();
  final policyMessage = isManualPayment
      ? null
      : _policyMessage(
          l10n,
          cancellationPolicy.describe(
            actor: ActorRole.student,
            sessionStartsAt: sessionStartsAt,
            pricingType: pricingType,
          ),
        );

  return showTilawaModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => _CancelSessionSheetBody(
      policyMessage: policyMessage,
      isManualPayment: isManualPayment,
    ),
  );
}

String _policyMessage(QuranSessionsLocalizations l10n, String key) {
  return switch (key) {
    'cancellation_blocked_within_notice' => l10n.cancelPolicyBlockedNotice,
    'cancellation_free_no_refund' => l10n.cancellationFreeNoRefund,
    'cancellation_full_refund' => l10n.cancelPolicyFullRefund,
    'cancellation_partial_refund' => l10n.cancelPolicyPartialRefund,
    _ => l10n.cancelPolicyNoRefund,
  };
}

class _CancelSessionSheetBody extends StatefulWidget {
  const _CancelSessionSheetBody({
    required this.policyMessage,
    required this.isManualPayment,
  });

  final String? policyMessage;
  final bool isManualPayment;

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
                  if (widget.isManualPayment)
                    const _ManualPaymentCancellationPolicy()
                  else if (widget.policyMessage case final message?)
                    Text(message),
                  SizedBox(height: tokens.spaceLarge),
                  TilawaTextField(
                    controller: _controller,
                    label: l10n.cancelReasonLabel,
                    hintText: l10n.cancelReasonHint,
                    errorText: _error,
                    maxLines: 3,
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

/// Cancellation-only copy for manual/off-app paid sessions.
class _ManualPaymentCancellationPolicy extends StatelessWidget {
  const _ManualPaymentCancellationPolicy();

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.manualPaymentCancellationPolicy, style: bodyStyle),
        SizedBox(height: tokens.spaceSmall),
        Text(
          l10n.manualPaymentCancellationSupportHint(
            ManualPaymentMarketConfig.egFallback.supportWhatsappNumber,
          ),
          style: bodyStyle,
        ),
      ],
    );
  }
}
