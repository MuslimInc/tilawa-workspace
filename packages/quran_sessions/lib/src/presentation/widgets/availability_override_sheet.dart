import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/availability_override.dart';
import '../../domain/entities/local_time.dart';
import '../../domain/entities/time_range.dart';
import '../../domain/services/vacation_override_validator.dart';
import 'availability_day_hours_row.dart';
import 'time_range_editor_sheet.dart';

/// Opens the dated-override editor (vacation / busy / custom hours) and returns
/// one [AvailabilityOverride] per calendar day in the chosen range, or `null`
/// if dismissed.
Future<List<AvailabilityOverride>?> showOverrideEditorSheet(
  BuildContext context, {
  required List<AvailabilityOverride> existingOverrides,
}) {
  return showTilawaModalBottomSheet<List<AvailabilityOverride>>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => _OverrideEditorSheet(
      existingOverrides: existingOverrides,
    ),
  );
}

class _OverrideEditorSheet extends StatefulWidget {
  const _OverrideEditorSheet({required this.existingOverrides});

  final List<AvailabilityOverride> existingOverrides;

  @override
  State<_OverrideEditorSheet> createState() => _OverrideEditorSheetState();
}

class _OverrideEditorSheetState extends State<_OverrideEditorSheet> {
  static const _validator = VacationOverrideValidator();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  OverrideType _type = OverrideType.unavailable;
  final List<TimeRange> _ranges = [
    const TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0)),
  ];

  bool get _hasValidDateRange => _validator.hasValidDateRange(
    startDate: _startDate,
    endDate: _endDate,
  );

  bool get _hasVacationOverlap =>
      _type == OverrideType.unavailable &&
      _validator.findFirstOverlappingVacationDay(
            startDate: _startDate,
            endDate: _endDate,
            existingOverrides: widget.existingOverrides,
          ) !=
          null;

  bool get _canSave =>
      _hasValidDateRange &&
      !_hasVacationOverlap &&
      (_type == OverrideType.unavailable || _ranges.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final material = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: TilawaBottomSheetScaffold(
        topBar: TilawaBottomSheetTitleRow(title: l10n.availabilityAddOverride),
        footer: TilawaButton(
          text: l10n.availabilitySave,
          isFullWidth: true,
          onPressed: _canSave ? _save : null,
        ),
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DateField(
                      label: l10n.availabilityOverrideStartDate,
                      formattedDate: material.formatMediumDate(_startDate),
                      onTap: () => _pickDate(isStart: true),
                    ),
                    SizedBox(height: tokens.spaceMedium),
                    _DateField(
                      label: l10n.availabilityOverrideEndDate,
                      formattedDate: material.formatMediumDate(_endDate),
                      onTap: () => _pickDate(isStart: false),
                    ),
                    if (!_hasValidDateRange) ...[
                      SizedBox(height: tokens.spaceSmall),
                      Text(
                        l10n.availabilityOverrideEndDateInvalid,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                    if (_hasVacationOverlap) ...[
                      SizedBox(height: tokens.spaceSmall),
                      Text(
                        l10n.availabilityVacationOverlapError,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                    SizedBox(height: tokens.spaceMedium),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChip(
                            label: l10n.availabilityOverrideUnavailable,
                            selected: _type == OverrideType.unavailable,
                            onTap: () => setState(
                              () => _type = OverrideType.unavailable,
                            ),
                          ),
                        ),
                        SizedBox(width: tokens.spaceSmall),
                        Expanded(
                          child: _TypeChip(
                            label: l10n.availabilityOverrideCustom,
                            selected: _type == OverrideType.custom,
                            onTap: () =>
                                setState(() => _type = OverrideType.custom),
                          ),
                        ),
                      ],
                    ),
                    if (_type == OverrideType.custom) ...[
                      SizedBox(height: tokens.spaceMedium),
                      Wrap(
                        spacing: tokens.spaceSmall,
                        runSpacing: tokens.spaceSmall,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (var i = 0; i < _ranges.length; i++)
                            AvailabilityRangePill(
                              range: _ranges[i],
                              onTap: () => _editRange(i),
                              onRemove: () =>
                                  setState(() => _ranges.removeAt(i)),
                            ),
                          AvailabilityAddRangeButton(onTap: _addRange),
                        ],
                      ),
                    ],
                    SizedBox(height: tokens.spaceSmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _addRange() async {
    final range = await showTimeRangeEditorSheet(context, existing: _ranges);
    if (range != null) setState(() => _ranges.add(range));
  }

  Future<void> _editRange(int index) async {
    final others = [
      for (var i = 0; i < _ranges.length; i++)
        if (i != index) _ranges[i],
    ];
    final range = await showTimeRangeEditorSheet(
      context,
      initial: _ranges[index],
      existing: others,
    );
    if (range != null) setState(() => _ranges[index] = range);
  }

  void _save() {
    if (!_canSave) return;

    final overrides = _type == OverrideType.unavailable
        ? _validator.expandVacationRange(
            startDate: _startDate,
            endDate: _endDate,
          )
        : _expandCustomOverrides();

    Navigator.of(context).pop(overrides);
  }

  List<AvailabilityOverride> _expandCustomOverrides() {
    final overrides = <AvailabilityOverride>[];
    var day = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final last = DateTime(_endDate.year, _endDate.month, _endDate.day);

    while (!day.isAfter(last)) {
      overrides.add(
        AvailabilityOverride(
          date: day,
          type: OverrideType.custom,
          intervals: List.unmodifiable(_ranges),
        ),
      );
      day = day.add(const Duration(days: 1));
    }
    return overrides;
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.formattedDate,
    required this.onTap,
  });

  final String label;
  final String formattedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TilawaReadOnlyField(
      prefixIcon: Icons.calendar_today_outlined,
      semanticLabel: label,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TilawaChip(
      label: label,
      onTap: onTap,
      backgroundColor: selected ? scheme.primary : scheme.surface,
      foregroundColor: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
      borderColor: selected ? scheme.primary : scheme.outlineVariant,
    );
  }
}
