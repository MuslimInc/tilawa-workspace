import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interaction_feedback.dart';

/// Adaptive switch with a guaranteed [kTilawaMinInteractiveDimension] hit target.
///
/// The control visual is fitted inside an optional [visualSlotSize] so rows can
/// keep a compact switch silhouette without shrinking the tap target (FR-001).
class TilawaSwitch extends StatelessWidget {
  const TilawaSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeTrackColor,
    this.activeThumbColor,
    this.visualSlotSize = const Size(48, 30),
    this.layoutSlotHeight,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeTrackColor;
  final Color? activeThumbColor;

  /// Visual bounds for [Switch.adaptive] inside the 44×44 dp hit box.
  final Size visualSlotSize;

  /// When set, the parent row only reserves this height while the 44×44 dp hit
  /// target overflows without expanding sibling rows (e.g. settings list rows).
  final double? layoutSlotHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hitSize = kTilawaMinInteractiveDimension;

    final Widget switchControl = Theme(
      data: theme.copyWith(
        switchTheme: theme.switchTheme.copyWith(
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: visualSlotSize.width,
          height: visualSlotSize.height,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (next) {
                      TilawaInteractionFeedback.trigger(
                        TilawaHaptic.selection,
                      );
                      onChanged!(next);
                    },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeTrackColor: activeTrackColor,
              activeThumbColor: activeThumbColor,
            ),
          ),
        ),
      ),
    );

    final Widget hitTarget = SizedBox(
      width: hitSize,
      height: hitSize,
      child: switchControl,
    );

    if (layoutSlotHeight == null) {
      return hitTarget;
    }

    return SizedBox(
      width: hitSize,
      height: layoutSlotHeight,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: hitSize,
        maxWidth: hitSize,
        minHeight: hitSize,
        maxHeight: hitSize,
        child: hitTarget,
      ),
    );
  }
}
