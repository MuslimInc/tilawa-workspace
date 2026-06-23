import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Confirms leaving Tilawa to open an external meeting link.
///
/// Returns `true` when the user taps **Open**; `false` when dismissed.
Future<bool> showExternalMeetingJoinSheet(
  BuildContext context, {
  required String meetingUrl,
}) {
  return showTilawaModalBottomSheet<bool>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => _ExternalMeetingJoinSheetBody(meetingUrl: meetingUrl),
  ).then((confirmed) => confirmed ?? false);
}

class _ExternalMeetingJoinSheetBody extends StatelessWidget {
  const _ExternalMeetingJoinSheetBody({required this.meetingUrl});

  final String meetingUrl;

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: meetingUrl));
    TilawaFeedback.showToast(
      context,
      message: context.quranSessionsL10n.externalMeetingJoinLinkCopied,
      variant: TilawaFeedbackVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return TilawaBottomSheetScaffold(
      topBar: TilawaBottomSheetTitleRow(title: l10n.externalMeetingJoinTitle),
      footer: TilawaBottomSheetActions(
        primaryLabel: l10n.externalMeetingJoinOpen,
        onPrimary: () => Navigator.pop(context, true),
        secondaryLabel: l10n.externalMeetingJoinCopy,
        onSecondary: () => _copyUrl(context),
      ),
      children: [
        Padding(
          padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
          child: Text(
            l10n.externalMeetingJoinBody,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
      ],
    );
  }
}
