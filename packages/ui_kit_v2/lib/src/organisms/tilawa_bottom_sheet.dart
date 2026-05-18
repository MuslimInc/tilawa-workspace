import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Branded bottom sheet content. Drag handle → optional title/subtitle →
/// children (slot). Mirrors `.tw-sheet`.
class TilawaBottomSheet extends StatelessWidget {
  const TilawaBottomSheet({
    required this.children,
    this.title,
    this.subtitle,
    this.footer,
    super.key,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            offset: Offset(0, -8),
            blurRadius: 32,
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0x2E0F172A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if ((title ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontFamily: TilawaFontFamily.ui,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.fg1,
                  ),
                ),
              ),
            if ((subtitle ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: TilawaFontFamily.ui,
                    fontSize: 13,
                    color: c.fg2,
                    height: 1.5,
                  ),
                ),
              ),
            ...children,
            if (footer != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: footer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper that opens [TilawaBottomSheet] via [showModalBottomSheet] with the
/// right shape + barrier colors.
Future<T?> showTilawaBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x520F172A),
    builder: builder,
  );
}
