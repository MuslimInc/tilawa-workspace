import 'dart:async';

import 'package:flutter/material.dart';

class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.error_outline,
    Color iconBackgroundColor = const Color(0xFFFF5A52),
    Color backgroundColor = const Color(0xFF1F1F1F),
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 4),
  }) {
    _timer?.cancel();
    _currentEntry?.remove();

    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (ctx) {
        final padding = MediaQuery.of(ctx).viewPadding.bottom;
        return Positioned(
          left: 16,
          right: 16,
          bottom: padding + 32,
          child: IgnorePointer(
            ignoring: true,
            child: _ToastContent(
              message: message,
              icon: icon,
              iconBackgroundColor: iconBackgroundColor,
              backgroundColor: backgroundColor,
              textColor: textColor,
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    _currentEntry = entry;

    _timer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    required this.icon,
    required this.iconBackgroundColor,
    required this.backgroundColor,
    required this.textColor,
  });

  final String message;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
