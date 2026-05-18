import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// iOS-style switch. 44×26 with a 22px white thumb.
/// Mirrors `.tw-toggle` from mobile.css.
class TilawaToggle extends StatelessWidget {
  const TilawaToggle({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;
    final disabled = onChanged == null;

    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: !disabled,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: GestureDetector(
          onTap: disabled ? null : () => onChanged!(!value),
          child: AnimatedContainer(
            duration: TilawaMotion.base,
            curve: TilawaMotion.standard,
            width: 44,
            height: 26,
            decoration: BoxDecoration(
              color: value ? c.brand : const Color(0x2E0F172A),
              borderRadius: TilawaRadii.brPill,
            ),
            child: AnimatedAlign(
              duration: TilawaMotion.base,
              curve: TilawaMotion.standard,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40000000),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
