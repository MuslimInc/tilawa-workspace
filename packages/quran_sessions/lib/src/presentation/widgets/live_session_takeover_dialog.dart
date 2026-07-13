import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../core/l10n_extensions.dart';
import '../../domain/failures/quran_sessions_failure.dart';

/// Shows the ADR-008 Phase 2 "Switch to this device" prompt when a live-session
/// join was denied because the same user is already active on another device.
///
/// [onSwitch] is invoked when the user chooses to take over (the caller retries
/// the join with `forceTakeover: true`). Never a whole-app sign-out — the
/// caller's other device is disconnected server-side via the live lock.
Future<void> showLiveSessionTakeoverDialog(
  BuildContext context,
  LiveSessionAlreadyActiveFailure failure, {
  required VoidCallback onSwitch,
}) {
  final l10n = context.quranSessionsL10n;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.liveSessionTakeoverTitle),
      content: Text(l10n.liveSessionTakeoverBody),
      actions: [
        TilawaButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          text: l10n.liveSessionTakeoverCancel,
        ),
        TilawaButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onSwitch();
          },
          text: l10n.liveSessionTakeoverSwitch,
        ),
      ],
    ),
  );
}
