import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom sheet collecting a mandatory dispute reason before opening a case.
Future<String?> showOpenDisputeSheet(BuildContext context) {
  return showTilawaModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => const _OpenDisputeSheetBody(),
  );
}

class _OpenDisputeSheetBody extends StatefulWidget {
  const _OpenDisputeSheetBody();

  @override
  State<_OpenDisputeSheetBody> createState() => _OpenDisputeSheetBodyState();
}

class _OpenDisputeSheetBodyState extends State<_OpenDisputeSheetBody> {
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

    return TilawaBottomSheetScaffold(
      topBar: TilawaBottomSheetTitleRow(
        title: l10n.openDisputeTitle,
        trailingClose: true,
        onClose: () => Navigator.pop<String?>(context, null),
      ),
      footer: TilawaBottomSheetActions(
        primaryLabel: l10n.openDisputeSubmit,
        onPrimary: _submit,
        secondaryLabel: l10n.openDisputeCancel,
        onSecondary: () => Navigator.pop<String?>(context, null),
      ),
      children: [
        SingleChildScrollView(
          padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.openDisputeSubtitle),
              SizedBox(height: tokens.spaceLarge),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.openDisputeReasonLabel,
                  hintText: l10n.openDisputeReasonHint,
                  errorText: _error,
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.length < OpenSessionDisputeUseCase.minReasonLength) {
      setState(
        () => _error = context.quranSessionsL10n.openDisputeReasonTooShort,
      );
      return;
    }
    Navigator.pop(context, reason);
  }
}
