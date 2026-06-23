import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// In-app call surface for mock/Agora/WebRTC joins.
///
/// Host app pushes this after [JoinSessionUseCase] succeeds for non-external
/// sessions. SDK-specific mute/end actions are injected via callbacks.
class InAppCallShellScreen extends StatefulWidget {
  const InAppCallShellScreen({
    super.key,
    required this.sessionId,
    this.onLeaveCall,
    this.onSetMicrophoneMuted,
  });

  final String sessionId;
  final Future<void> Function()? onLeaveCall;
  final Future<void> Function({required bool muted})? onSetMicrophoneMuted;

  @override
  State<InAppCallShellScreen> createState() => _InAppCallShellScreenState();
}

class _InAppCallShellScreenState extends State<InAppCallShellScreen> {
  bool _isMuted = false;
  bool _muteInProgress = false;

  Future<void> _toggleMute() async {
    if (_muteInProgress || widget.onSetMicrophoneMuted == null) {
      return;
    }

    final nextMuted = !_isMuted;
    setState(() => _muteInProgress = true);
    try {
      await widget.onSetMicrophoneMuted!(muted: nextMuted);
      if (mounted) {
        setState(() => _isMuted = nextMuted);
      }
    } finally {
      if (mounted) {
        setState(() => _muteInProgress = false);
      }
    }
  }

  Future<void> _endCall() async {
    await widget.onLeaveCall?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final canMute = widget.onSetMicrophoneMuted != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inAppCallShellTitle)),
      body: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.inAppCallShellBody,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: tokens.spaceMedium),
            Text(
              widget.sessionId,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            if (canMute) ...[
              Semantics(
                button: true,
                label: _isMuted
                    ? l10n.inAppCallShellUnmute
                    : l10n.inAppCallShellMute,
                child: TilawaButton(
                  text: _isMuted
                      ? l10n.inAppCallShellUnmute
                      : l10n.inAppCallShellMute,
                  isFullWidth: true,
                  size: TilawaButtonSize.large,
                  variant: TilawaButtonVariant.secondary,
                  isLoading: _muteInProgress,
                  onPressed: _muteInProgress ? null : _toggleMute,
                  leadingIcon: Icon(
                    _isMuted ? Icons.mic_off_outlined : Icons.mic_none_outlined,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceMedium),
            ],
            TilawaButton(
              text: l10n.inAppCallShellEndCall,
              isFullWidth: true,
              size: TilawaButtonSize.large,
              variant: TilawaButtonVariant.secondary,
              onPressed: _endCall,
              leadingIcon: Icon(
                Icons.call_end_outlined,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
