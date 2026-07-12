import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/services/session_taken_over_notifier.dart';

/// Shows a "Moved to another device" dialog when a live Quran session the user
/// is in is taken over by the same user from another device (ADR-008 Phase 2).
///
/// This is session-scoped and never signs the user out — the RTC provider
/// evicts the old device's participant server-side; this listener only surfaces
/// what happened. Mirrors [SessionRevokedNavigationListener] but for the
/// per-session takeover control message instead of the whole-app revoke.
class SessionTakenOverListener extends StatefulWidget {
  const SessionTakenOverListener({super.key, required this.child});

  final Widget child;

  @override
  State<SessionTakenOverListener> createState() =>
      _SessionTakenOverListenerState();
}

class _SessionTakenOverListenerState extends State<SessionTakenOverListener> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = GetIt.instance<SessionTakenOverNotifier>()
        .onSessionTakenOver
        .listen(_handleTakenOver);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleTakenOver(String sessionId) {
    if (!mounted) return;
    final l10n = context.quranSessionsL10n;
    showTilawaFormDialog<void>(
      context: context,
      title: l10n.liveSessionTakenOverTitle,
      bodyBuilder: (dialogContext) => Text(
        l10n.liveSessionTakenOverBody,
        style: Theme.of(dialogContext).textTheme.bodyLarge,
      ),
      primaryLabel: l10n.liveSessionTakenOverDismiss,
      onPrimary: (dialogContext) => Navigator.of(dialogContext).pop(),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
