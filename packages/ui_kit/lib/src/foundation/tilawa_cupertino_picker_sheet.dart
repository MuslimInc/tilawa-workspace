import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../atoms/tilawa_button.dart';
import '../molecules/tilawa_cupertino_wheel_picker.dart';
import '../molecules/tilawa_picker_segment_card.dart';
import 'component_tokens.dart';
import 'tilawa_bottom_sheet_scaffold.dart';
import 'tilawa_bottom_sheet_title_row.dart';
import 'tilawa_modal_bottom_sheet.dart';

/// Label and value for one segment in [showTilawaDualCupertinoPickerSheet].
@immutable
class TilawaPickerSegment<T> {
  const TilawaPickerSegment({required this.label, required this.value});

  final String label;
  final T value;
}

/// Bottom sheet layout for a token-styled Cupertino wheel picker.
class TilawaCupertinoPickerSheet extends StatelessWidget {
  const TilawaCupertinoPickerSheet({
    super.key,
    required this.title,
    required this.picker,
    required this.primaryLabel,
    required this.onPrimary,
    this.header,
    this.errorText,
    this.trailingClose = false,
  });

  final String title;
  final Widget? header;
  final Widget picker;
  final String? errorText;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool trailingClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.cupertinoWheelPicker;
    final bodyPadding = TilawaBottomSheetScaffold.resolvedBodyPadding(context);

    return TilawaBottomSheetScaffold(
      topBar: TilawaBottomSheetTitleRow(
        title: title,
        trailingClose: trailingClose,
      ),
      footer: TilawaButton(
        text: primaryLabel,
        isFullWidth: true,
        onPressed: onPrimary,
      ),
      children: [
        if (header != null || errorText != null)
          Padding(
            padding: bodyPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?header,
                if (errorText != null) ...[
                  SizedBox(height: tokens.segmentGap),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        SizedBox(height: tokens.wheelTopSpacing),
        picker,
      ],
    );
  }
}

enum _DualPickerEditing { start, end }

/// Opens a dual-segment Cupertino wheel sheet for editing two related values.
Future<(T start, T end)?> showTilawaDualCupertinoPickerSheet<T>({
  required BuildContext context,
  required String title,
  required TilawaPickerSegment<T> start,
  required TilawaPickerSegment<T> end,
  required String Function(BuildContext context, T value) formatValue,
  required DateTime Function(T value) toDateTime,
  required T Function(DateTime dateTime) fromDateTime,
  required String primaryLabel,
  required bool Function(T start, T end) canConfirm,
  String? Function(BuildContext context, T start, T end)? errorText,
  CupertinoDatePickerMode mode = CupertinoDatePickerMode.time,
  int minuteInterval = 1,
}) {
  return showTilawaModalBottomSheet<(T, T)>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => _DualCupertinoPickerSheetBody<T>(
      title: title,
      initialStart: start.value,
      initialEnd: end.value,
      startLabel: start.label,
      endLabel: end.label,
      formatValue: formatValue,
      toDateTime: toDateTime,
      fromDateTime: fromDateTime,
      primaryLabel: primaryLabel,
      canConfirm: canConfirm,
      errorText: errorText,
      mode: mode,
      minuteInterval: minuteInterval,
    ),
  );
}

class _DualCupertinoPickerSheetBody<T> extends StatefulWidget {
  const _DualCupertinoPickerSheetBody({
    required this.title,
    required this.initialStart,
    required this.initialEnd,
    required this.startLabel,
    required this.endLabel,
    required this.formatValue,
    required this.toDateTime,
    required this.fromDateTime,
    required this.primaryLabel,
    required this.canConfirm,
    required this.errorText,
    required this.mode,
    required this.minuteInterval,
  });

  final String title;
  final T initialStart;
  final T initialEnd;
  final String startLabel;
  final String endLabel;
  final String Function(BuildContext context, T value) formatValue;
  final DateTime Function(T value) toDateTime;
  final T Function(DateTime dateTime) fromDateTime;
  final String primaryLabel;
  final bool Function(T start, T end) canConfirm;
  final String? Function(BuildContext context, T start, T end)? errorText;
  final CupertinoDatePickerMode mode;
  final int minuteInterval;

  @override
  State<_DualCupertinoPickerSheetBody<T>> createState() =>
      _DualCupertinoPickerSheetBodyState<T>();
}

class _DualCupertinoPickerSheetBodyState<T>
    extends State<_DualCupertinoPickerSheetBody<T>> {
  late T _start = widget.initialStart;
  late T _end = widget.initialEnd;
  _DualPickerEditing _editing = _DualPickerEditing.start;

  T get _active => _editing == _DualPickerEditing.start ? _start : _end;

  void _onChanged(DateTime value) {
    final updated = widget.fromDateTime(value);
    setState(() {
      if (_editing == _DualPickerEditing.start) {
        _start = updated;
      } else {
        _end = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).componentTokens.cupertinoWheelPicker;
    final error = widget.errorText?.call(context, _start, _end);
    final canConfirm = widget.canConfirm(_start, _end);

    return TilawaCupertinoPickerSheet(
      title: widget.title,
      errorText: error,
      primaryLabel: widget.primaryLabel,
      onPrimary: canConfirm
          ? () => Navigator.of(context).pop((_start, _end))
          : null,
      header: Row(
        children: [
          Expanded(
            child: TilawaPickerSegmentCard(
              label: widget.startLabel,
              value: widget.formatValue(context, _start),
              selected: _editing == _DualPickerEditing.start,
              onTap: () => setState(() => _editing = _DualPickerEditing.start),
            ),
          ),
          SizedBox(width: tokens.segmentGap),
          Expanded(
            child: TilawaPickerSegmentCard(
              label: widget.endLabel,
              value: widget.formatValue(context, _end),
              selected: _editing == _DualPickerEditing.end,
              onTap: () => setState(() => _editing = _DualPickerEditing.end),
            ),
          ),
        ],
      ),
      picker: TilawaCupertinoWheelPicker(
        key: ValueKey(_editing),
        mode: widget.mode,
        minuteInterval: widget.minuteInterval,
        initialDateTime: widget.toDateTime(_active),
        onDateTimeChanged: _onChanged,
      ),
    );
  }
}
