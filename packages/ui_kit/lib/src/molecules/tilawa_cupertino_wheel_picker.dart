import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// Token-styled wrapper around the public [CupertinoDatePicker] wheel.
class TilawaCupertinoWheelPicker extends StatelessWidget {
  const TilawaCupertinoWheelPicker({
    super.key,
    required this.mode,
    required this.initialDateTime,
    required this.onDateTimeChanged,
    this.minuteInterval = 1,
    this.use24hFormat,
    this.minimumDate,
    this.maximumDate,
    this.minimumYear = 1,
    this.maximumYear,
    this.wheelTextDirection = TextDirection.ltr,
  });

  final CupertinoDatePickerMode mode;
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onDateTimeChanged;
  final int minuteInterval;
  final bool? use24hFormat;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final int minimumYear;
  final int? maximumYear;

  /// Keeps hour | minute | AM/PM columns readable in RTL app locales.
  final TextDirection wheelTextDirection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.cupertinoWheelPicker;
    final colorScheme = theme.colorScheme;
    final resolved24h =
        use24hFormat ?? MediaQuery.of(context).alwaysUse24HourFormat;
    final cupertinoTheme = CupertinoTheme.of(context);
    final pickerTextStyle = theme.textTheme.titleLarge?.copyWith(
      color: colorScheme.onSurface,
    );

    return SizedBox(
      height: tokens.pickerHeight,
      child: Directionality(
        textDirection: wheelTextDirection,
        child: CupertinoTheme(
          data: cupertinoTheme.copyWith(
            textTheme: cupertinoTheme.textTheme.copyWith(
              dateTimePickerTextStyle: pickerTextStyle,
            ),
          ),
          child: CupertinoDatePicker(
            mode: mode,
            use24hFormat: resolved24h,
            minuteInterval: minuteInterval,
            minimumDate: minimumDate,
            maximumDate: maximumDate,
            minimumYear: minimumYear,
            maximumYear: maximumYear,
            backgroundColor: tokens.pickerBackgroundColor,
            initialDateTime: initialDateTime,
            onDateTimeChanged: onDateTimeChanged,
            selectionOverlayBuilder: _selectionOverlayBuilder(tokens),
          ),
        ),
      ),
    );
  }

  SelectionOverlayBuilder _selectionOverlayBuilder(
    TilawaCupertinoWheelPickerTokens tokens,
  ) {
    return (
      BuildContext context, {
      required int selectedIndex,
      required int columnCount,
    }) {
      if (selectedIndex == 0) {
        return CupertinoPickerDefaultSelectionOverlay(
          background: tokens.selectionOverlayColor,
          capEndEdge: false,
        );
      }
      if (selectedIndex == columnCount - 1) {
        return CupertinoPickerDefaultSelectionOverlay(
          background: tokens.selectionOverlayColor,
          capStartEdge: false,
        );
      }
      return CupertinoPickerDefaultSelectionOverlay(
        background: tokens.selectionOverlayColor,
        capStartEdge: false,
        capEndEdge: false,
      );
    };
  }
}
