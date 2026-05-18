import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

enum TilawaToastTone {
  neutral,
  success,
  error,
}

/// Compact in-app toast. Use `showTilawaToast` to display from a tap. Sits
/// above any NowPlaying dock / tab bar. Mirrors `.tw-toast`.
class TilawaToast extends StatelessWidget {
  const TilawaToast({
    required this.message,
    this.tone = TilawaToastTone.neutral,
    super.key,
  });

  final String message;
  final TilawaToastTone tone;

  @override
  Widget build(BuildContext context) {
    final iconData = switch (tone) {
      TilawaToastTone.success => Icons.check_circle_outline,
      TilawaToastTone.error => Icons.error_outline,
      TilawaToastTone.neutral => Icons.info_outline,
    };
    final iconColor = switch (tone) {
      TilawaToastTone.success => const Color(0xFF7AD59F),
      TilawaToastTone.error => const Color(0xFFFF9999),
      TilawaToastTone.neutral => Colors.white,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xF00F172A),
        borderRadius: TilawaRadii.brMd,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 20),
            blurRadius: 40,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: TilawaFontFamily.ui,
                fontSize: 13,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience helper that shows a [TilawaToast] using a transient overlay.
void showTilawaToast(
  BuildContext context, {
  required String message,
  TilawaToastTone tone = TilawaToastTone.neutral,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: TilawaToast(message: message, tone: tone),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Future.delayed(duration, () {
    if (entry.mounted) entry.remove();
  });
}
