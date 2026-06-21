import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/availability_override.dart';
import '../../domain/entities/local_time.dart';
import '../../domain/entities/time_range.dart';
import 'time_range_editor_sheet.dart';

/// Opens the dated-override editor (vacation / busy / custom hours) and returns
/// the configured [AvailabilityOverride], or `null` if dismissed.
Future<AvailabilityOverride?> showOverrideEditorSheet(BuildContext context) {
  return showTilawaModalBottomSheet<AvailabilityOverride>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => const _OverrideEditorSheet(),
  );
}

class _OverrideEditorSheet extends StatefulWidget {
  const _OverrideEditorSheet();

  @override
  State<_OverrideEditorSheet> createState() => _OverrideEditorSheetState();
}

class _OverrideEditorSheetState extends State<_OverrideEditorSheet> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  OverrideType _type = OverrideType.unavailable;
  final List<TimeRange> _ranges = [
    const TimeRange(start: LocalTime(9, 0), end: LocalTime(17, 0)),
  ];

  bool get _canSave => _type == OverrideType.unavailable || _ranges.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final material = MaterialLocalizations.of(context);

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
                    TilawaReadOnlyField(
                      prefixIcon: Icons.calendar_today_outlined,
                      semanticLabel: l10n.availabilityOverrideDate,
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.availabilityOverrideDate,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          Text(
                            material.formatMediumDate(_date),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
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
                      for (var i = 0; i < _ranges.length; i++)
                        _CustomRangeRow(
                          range: _ranges[i],
                          onEdit: () => _editRange(i),
                          onRemove: () => setState(() => _ranges.removeAt(i)),
                        ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: _addRange,
                          icon: const Icon(Icons.add),
                          label: Text(l10n.availabilityAddRange),
                        ),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
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
    Navigator.of(context).pop(
      AvailabilityOverride(
        date: _date,
        type: _type,
        intervals: _type == OverrideType.custom
            ? List.unmodifiable(_ranges)
            : const [],
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

class _CustomRangeRow extends StatelessWidget {
  const _CustomRangeRow({
    required this.range,
    required this.onEdit,
    required this.onRemove,
  });

  final TimeRange range;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final use24 = MediaQuery.of(context).alwaysUse24HourFormat;
    String fmt(LocalTime t) => material.formatTimeOfDay(
      TimeOfDay(hour: t.hour % 24, minute: t.minute),
      alwaysUse24HourFormat: use24,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onEdit,
      title: Text('${fmt(range.start)} - ${fmt(range.end)}'),
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.close),
      ),
    );
  }
}
