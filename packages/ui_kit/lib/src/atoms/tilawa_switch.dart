import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';

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
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeTrackColor;
  final Color? activeThumbColor;

  /// Visual bounds for [Switch.adaptive] inside the 48×48 dp hit box.
  final Size visualSlotSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hitSize = kTilawaMinInteractiveDimension;

    return SizedBox(
      width: hitSize,
      height: hitSize,
      child: Theme(
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
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeTrackColor: activeTrackColor,
                activeThumbColor: activeThumbColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
