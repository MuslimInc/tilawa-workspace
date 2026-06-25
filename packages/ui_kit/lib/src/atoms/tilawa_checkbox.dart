import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interaction_feedback.dart';

/// Adaptive checkbox with a guaranteed [kMeMuslimMinInteractiveDimension] hit
/// target.
///
/// The control visual is fitted inside [visualSlotSize] so rows can keep a
/// compact checkbox silhouette without shrinking the tap target (FR-001).
class TilawaCheckbox extends StatelessWidget {
  const TilawaCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.activeColor,
    this.visualSlotSize = const Size(24, 24),
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;
  final Color? activeColor;

  /// Visual bounds for [Checkbox.adaptive] inside the 48×48 dp hit box.
  final Size visualSlotSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hitSize = kMeMuslimMinInteractiveDimension;

    return SizedBox(
      width: hitSize,
      height: hitSize,
      child: Theme(
        data: theme.copyWith(
          checkboxTheme: theme.checkboxTheme.copyWith(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: visualSlotSize.width,
            height: visualSlotSize.height,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: Checkbox.adaptive(
                value: value,
                tristate: tristate,
                onChanged: onChanged == null
                    ? null
                    : (next) {
                        TilawaInteractionFeedback.trigger(
                          TilawaHaptic.selection,
                        );
                        onChanged!(next);
                      },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: activeColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
