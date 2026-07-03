import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Centered offline placeholder for network-required Quran Sessions screens.
///
/// Matches the Support screen pattern: wifi-off icon and retry action.
class QuranSessionsOfflineState extends StatelessWidget {
  const QuranSessionsOfflineState({
    super.key,
    required this.onRetry,
    this.isRetrying = false,
  });

  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return TilawaErrorState(
      icon: Icons.wifi_off_outlined,
      title: l10n.offlineConnectionRequired,
      retryLabel: l10n.retry,
      onRetry: onRetry,
      isRetrying: isRetrying,
    );
  }
}
