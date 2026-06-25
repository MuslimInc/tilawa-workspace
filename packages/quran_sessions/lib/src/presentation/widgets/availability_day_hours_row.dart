import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/time_range.dart';

/// Row of editable availability range chips with an add-range control.
///
/// Used on [WeeklyAvailabilityScreen] for per-day (or shared) working hours.
class AvailabilityDayHoursRow extends StatelessWidget {
  const AvailabilityDayHoursRow({
    super.key,
    required this.label,
    required this.ranges,
    required this.onAddRange,
    required this.onEditRange,
    required this.onRemoveRange,
  });

  final String label;
  final List<TimeRange> ranges;
  final VoidCallback onAddRange;
  final ValueChanged<int> onEditRange;
  final ValueChanged<int> onRemoveRange;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: tokens.spaceHuge * 1.6,
          child: Padding(
            padding: EdgeInsets.only(top: tokens.spaceSmall),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: tokens.spaceSmall,
            runSpacing: tokens.spaceSmall,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < ranges.length; i++)
                AvailabilityRangePill(
                  range: ranges[i],
                  onTap: () => onEditRange(i),
                  onRemove: () => onRemoveRange(i),
                ),
              AvailabilityAddRangeButton(onTap: onAddRange),
            ],
          ),
        ),
      ],
    );
  }
}

EdgeInsets availabilityRangeChipPadding(MeMuslimDesignTokens tokens) {
  return EdgeInsets.symmetric(
    horizontal: tokens.spaceMedium,
    vertical: tokens.spaceSmall,
  );
}

double availabilityRangeChipHeight(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  final textStyle = Theme.of(context).textTheme.bodyMedium;
  final fontSize = textStyle?.fontSize ?? 14.0;
  final lineHeight = textStyle?.height ?? 1.43;
  return tokens.spaceSmall * 2 + fontSize * lineHeight;
}

/// A single editable availability time-range chip.
class AvailabilityRangePill extends StatelessWidget {
  const AvailabilityRangePill({
    super.key,
    required this.range,
    required this.onTap,
    required this.onRemove,
  });

  final TimeRange range;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final use24 = MediaQuery.of(context).alwaysUse24HourFormat;
    String fmt(int h, int m) => material.formatTimeOfDay(
      TimeOfDay(hour: h % 24, minute: m),
      alwaysUse24HourFormat: use24,
    );

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(tokens.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: availabilityRangeChipHeight(context),
          ),
          child: Padding(
            padding: availabilityRangeChipPadding(tokens),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${fmt(range.start.hour, range.start.minute)} '
                  '- ${fmt(range.end.hour, range.end.minute)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(width: tokens.spaceSmall),
                InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: Icon(Icons.close, size: tokens.iconSizeSmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact add-range control sized to match [AvailabilityRangePill].
class AvailabilityAddRangeButton extends StatelessWidget {
  const AvailabilityAddRangeButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.quranSessionsL10n;

    return Semantics(
      button: true,
      label: l10n.availabilityAddRange,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: availabilityRangeChipHeight(context),
            ),
            child: Padding(
              padding: availabilityRangeChipPadding(tokens),
              child: Align(
                alignment: AlignmentDirectional.center,
                widthFactor: 1,
                heightFactor: 1,
                child: Icon(
                  Icons.add_circle_outline,
                  size: tokens.iconSizeSmall,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
