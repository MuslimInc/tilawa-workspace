import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../theme/quran_sessions_theme.dart';

/// Underline segmented tabs for My Sessions (reference-style scan pattern).
class QuranSessionsSegmentedTabs<T> extends StatelessWidget {
  const QuranSessionsSegmentedTabs({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onValueChanged,
  });

  final List<TilawaSegment<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: feature.screenPadding,
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) SizedBox(width: tokens.spaceSmall),
            Expanded(
              child: _UnderlineTab<T>(
                segment: segments[i],
                selected: segments[i].value == selectedValue,
                onTap: segments[i].enabled
                    ? () => onValueChanged(segments[i].value)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnderlineTab<T> extends StatelessWidget {
  const _UnderlineTab({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final TilawaSegment<T> segment;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final enabled = segment.enabled && onTap != null;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: segment.label,
      hint: segment.semanticsHint,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(feature.chipRadius),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
          child: Column(
            children: [
              Text(
                segment.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: feature.chipLabelStyle.copyWith(
                  color: !enabled
                      ? feature.disabledForeground
                      : selected
                      ? feature.primaryColor
                      : feature.helperTextColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              SizedBox(height: tokens.spaceExtraSmall / 2),
              AnimatedContainer(
                duration: tokens.durationFast,
                height: tokens.progressHeight,
                decoration: BoxDecoration(
                  color: selected && enabled
                      ? feature.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(feature.chipRadius),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
