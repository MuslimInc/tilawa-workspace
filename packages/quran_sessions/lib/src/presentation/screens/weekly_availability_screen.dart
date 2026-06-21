import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/availability_override.dart';
import '../../domain/entities/slot_duration.dart';
import '../../domain/entities/time_range.dart';
import '../../domain/entities/weekday.dart';
import '../blocs/availability/availability_cubit.dart';
import '../blocs/availability/availability_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/availability_override_sheet.dart';
import '../widgets/time_range_editor_sheet.dart';

/// MENA-first curated IANA zones offered in the timezone picker.
const _timezoneOptions = <String>[
  'Africa/Cairo',
  'Asia/Riyadh',
  'Asia/Dubai',
  'Asia/Qatar',
  'Asia/Kuwait',
  'Asia/Baghdad',
  'Asia/Amman',
  'Asia/Jerusalem',
  'Asia/Beirut',
  'Africa/Khartoum',
  'Africa/Tripoli',
  'Africa/Algiers',
  'Africa/Tunis',
  'Africa/Casablanca',
  'Europe/Istanbul',
  'Asia/Karachi',
  'Asia/Jakarta',
  'Europe/London',
  'UTC',
];

/// Calendly-inspired weekly availability editor. The teacher defines recurring
/// hours per day (or shared across days) and dated overrides; bookable slots
/// are generated from these rules rather than entered one at a time.
class WeeklyAvailabilityScreen extends StatefulWidget {
  const WeeklyAvailabilityScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  State<WeeklyAvailabilityScreen> createState() =>
      _WeeklyAvailabilityScreenState();
}

class _WeeklyAvailabilityScreenState extends State<WeeklyAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  )..addListener(_onTabChanged);

  @override
  void initState() {
    super.initState();
    context.read<AvailabilityCubit>().load(widget.teacherId);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.availabilityTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.availabilityTabHours),
            Tab(text: l10n.availabilityTabOverrides),
          ],
        ),
      ),
      body: BlocConsumer<AvailabilityCubit, AvailabilityState>(
        listenWhen: (prev, curr) =>
            prev.saveTick != curr.saveTick || prev.failure != curr.failure,
        listener: (context, state) {
          if (state.saveTick > 0 && state.failure == null) {
            TilawaFeedback.showToast(
              context,
              message: l10n.availabilitySavedToast,
              variant: TilawaFeedbackVariant.success,
            );
          }
          if (state.failure != null) {
            TilawaFeedback.showToast(
              context,
              message: state.failure!.toLocalizedMessage(context),
              variant: TilawaFeedbackVariant.error,
            );
          }
        },
        builder: (context, state) => switch (state.status) {
          AvailabilityStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          AvailabilityStatus.error => Center(
            child: TilawaEmptyState(
              icon: Icons.error_outline,
              title: l10n.availabilityLoadError,
              action: TilawaButton(
                text: l10n.retry,
                onPressed: () =>
                    context.read<AvailabilityCubit>().load(widget.teacherId),
              ),
            ),
          ),
          AvailabilityStatus.ready => TabBarView(
            controller: _tabController,
            children: [
              _HoursTab(state: state),
              _OverridesTab(state: state),
            ],
          ),
        },
      ),
      bottomNavigationBar: _buildFooter(context),
    );
  }

  Widget? _buildFooter(BuildContext context) {
    final state = context.watch<AvailabilityCubit>().state;
    if (state.status != AvailabilityStatus.ready || _tabController.index != 0) {
      return null;
    }
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return TilawaBottomActionArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isDirty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: tokens.spaceSmall,
                  color: scheme.tertiary,
                ),
                SizedBox(width: tokens.spaceExtraSmall),
                Text(
                  l10n.availabilityUnsavedChanges,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSmall),
          ],
          Row(
            children: [
              Expanded(
                child: TilawaButton(
                  text: l10n.cancel,
                  variant: TilawaButtonVariant.outline,
                  onPressed: () => _onCancel(context, state),
                ),
              ),
              SizedBox(width: tokens.spaceMedium),
              Expanded(
                child: TilawaButton(
                  text: l10n.availabilitySave,
                  isLoading: state.isSaving,
                  onPressed: state.isSaving
                      ? null
                      : () => context.read<AvailabilityCubit>().save(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onCancel(BuildContext context, AvailabilityState state) async {
    if (!state.isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = context.quranSessionsL10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.availabilityDiscardChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.availabilityKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.availabilityDiscardConfirm),
          ),
        ],
      ),
    );
    if (discard == true && context.mounted) Navigator.of(context).pop();
  }
}

// ── Hours tab ─────────────────────────────────────────────────────────────────

class _HoursTab extends StatelessWidget {
  const _HoursTab({required this.state});

  final AvailabilityState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final cubit = context.read<AvailabilityCubit>();
    final draft = state.draft;
    final openDays = draft.openDays.toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceLarge,
        tokens.spaceLarge,
        tokens.spaceXXL,
      ),
      children: [
        _DayChips(state: state),
        SizedBox(height: tokens.spaceLarge),
        const TilawaDivider(),
        _SwitchRow(
          label: l10n.availabilityUseSameHours,
          value: state.useSameHoursForAllDays,
          onChanged: cubit.setUseSameHoursForAllDays,
        ),
        const TilawaDivider(),
        SizedBox(height: tokens.spaceMedium),
        _PickerRow(
          icon: Icons.public,
          label: l10n.availabilityTimezone,
          value: draft.timezone,
          onTap: () => _pickTimezone(context),
        ),
        SizedBox(height: tokens.spaceMedium),
        _PickerRow(
          icon: Icons.timelapse_outlined,
          label: l10n.availabilitySessionLength,
          value: l10n.availabilityDurationMinutes(draft.slotDuration.minutes),
          onTap: () => _pickDuration(context),
        ),
        SizedBox(height: tokens.spaceMedium),
        const TilawaDivider(),
        SizedBox(height: tokens.spaceMedium),
        if (openDays.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceLarge),
            child: Text(
              l10n.availabilityDayClosed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (state.useSameHoursForAllDays)
          _DayHoursRow(
            label: l10n.availabilityHoursRow,
            ranges: draft.rangesFor(openDays.first),
            day: openDays.first,
          )
        else
          for (final day in openDays) ...[
            _DayHoursRow(
              label: _weekdayLabel(l10n, day),
              ranges: draft.rangesFor(day),
              day: day,
            ),
            SizedBox(height: tokens.spaceSmall),
          ],
      ],
    );
  }

  Future<void> _pickTimezone(BuildContext context) async {
    final cubit = context.read<AvailabilityCubit>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimezonePickerSheet(current: state.draft.timezone),
    );
    if (selected != null) cubit.setTimezone(selected);
  }

  Future<void> _pickDuration(BuildContext context) async {
    final cubit = context.read<AvailabilityCubit>();
    final selected = await showModalBottomSheet<SlotDuration>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DurationPickerSheet(current: state.draft.slotDuration),
    );
    if (selected != null) cubit.setDuration(selected);
  }
}

// ── Day chips (Sat → Fri) ─────────────────────────────────────────────────────

class _DayChips extends StatelessWidget {
  const _DayChips({required this.state});

  final AvailabilityState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<AvailabilityCubit>();

    return Wrap(
      spacing: tokens.spaceSmall,
      runSpacing: tokens.spaceSmall,
      children: [
        for (final day in Weekday.values)
          Builder(
            builder: (context) {
              final isOpen = state.draft.isOpenOn(day);
              return TilawaChip(
                label: _weekdayShort(l10n, day),
                onTap: () => cubit.toggleDay(day, !isOpen),
                backgroundColor: isOpen ? scheme.primary : scheme.surface,
                foregroundColor: isOpen
                    ? scheme.onPrimary
                    : scheme.onSurfaceVariant,
                borderColor: isOpen ? scheme.primary : scheme.outlineVariant,
              );
            },
          ),
      ],
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────────────

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceSmall),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          TilawaSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Picker row (timezone / duration) ──────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    return TilawaReadOnlyField(
      onTap: onTap,
      prefixIcon: icon,
      semanticLabel: label,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: tokens.spaceSmall),
          Icon(Icons.edit_outlined, size: tokens.iconSizeSmall),
        ],
      ),
    );
  }
}

// ── Day hours row ─────────────────────────────────────────────────────────────

class _DayHoursRow extends StatelessWidget {
  const _DayHoursRow({
    required this.label,
    required this.ranges,
    required this.day,
  });

  final String label;
  final List<TimeRange> ranges;
  final Weekday day;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final cubit = context.read<AvailabilityCubit>();

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
                _RangePill(
                  range: ranges[i],
                  onTap: () => _editRange(context, i),
                  onRemove: () => cubit.removeRange(day, i),
                ),
              _AddRangeButton(onTap: () => _addRange(context)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addRange(BuildContext context) async {
    final cubit = context.read<AvailabilityCubit>();
    final range = await showTimeRangeEditorSheet(context, existing: ranges);
    if (range != null) cubit.addRange(day, range);
  }

  Future<void> _editRange(BuildContext context, int index) async {
    final cubit = context.read<AvailabilityCubit>();
    final others = [
      for (var i = 0; i < ranges.length; i++)
        if (i != index) ranges[i],
    ];
    final range = await showTimeRangeEditorSheet(
      context,
      initial: ranges[index],
      existing: others,
    );
    if (range != null) cubit.updateRange(day, index, range);
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
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
    );
  }
}

class _AddRangeButton extends StatelessWidget {
  const _AddRangeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      tooltip: context.quranSessionsL10n.availabilityAddRange,
      icon: Icon(Icons.add_circle_outline, color: scheme.primary),
      iconSize: tokens.iconSizeLarge,
    );
  }
}

// ── Overrides tab ─────────────────────────────────────────────────────────────

class _OverridesTab extends StatelessWidget {
  const _OverridesTab({required this.state});

  final AvailabilityState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final cubit = context.read<AvailabilityCubit>();
    final material = MaterialLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: state.overrides.isEmpty
              ? Center(
                  child: TilawaEmptyState(
                    icon: Icons.event_busy_outlined,
                    title: l10n.availabilityOverridesEmpty,
                    subtitle: l10n.availabilityOverridesEmptyHint,
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(tokens.spaceLarge),
                  itemCount: state.overrides.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: tokens.spaceSmall),
                  itemBuilder: (context, index) {
                    final override = state.overrides[index];
                    return _OverrideTile(
                      title: material.formatMediumDate(override.date),
                      subtitle: override.type == OverrideType.unavailable
                          ? l10n.availabilityOverrideUnavailable
                          : l10n.availabilityOverrideCustom,
                      onRemove: () => cubit.removeOverride(override.dateKey),
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.all(tokens.spaceLarge),
          child: TilawaButton(
            text: l10n.availabilityAddOverride,
            isFullWidth: true,
            variant: TilawaButtonVariant.secondary,
            leadingIcon: const Icon(Icons.add),
            onPressed: () => _addOverride(context),
          ),
        ),
      ],
    );
  }

  Future<void> _addOverride(BuildContext context) async {
    final cubit = context.read<AvailabilityCubit>();
    final override = await showOverrideEditorSheet(context);
    if (override != null) cubit.addOverride(override);
  }
}

class _OverrideTile extends StatelessWidget {
  const _OverrideTile({
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return TilawaCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            tooltip: context.quranSessionsL10n.availabilityRemoveRange,
          ),
        ],
      ),
    );
  }
}

// ── Timezone picker sheet ─────────────────────────────────────────────────────

class _TimezonePickerSheet extends StatelessWidget {
  const _TimezonePickerSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;
    final options = {current, ..._timezoneOptions}.toList();

    return TilawaBottomSheetScaffold(
      topBar: TilawaBottomSheetTitleRow(
        title: l10n.availabilityTimezonePickerTitle,
      ),
      children: [
        for (final tz in options)
          ListTile(
            title: Text(tz),
            trailing: tz == current
                ? Icon(Icons.check, color: scheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(tz),
          ),
      ],
    );
  }
}

// ── Duration picker sheet ─────────────────────────────────────────────────────

class _DurationPickerSheet extends StatelessWidget {
  const _DurationPickerSheet({required this.current});

  final SlotDuration current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;

    return TilawaBottomSheetScaffold(
      topBar: TilawaBottomSheetTitleRow(title: l10n.availabilitySessionLength),
      children: [
        for (final duration in SlotDuration.presets)
          ListTile(
            title: Text(l10n.availabilityDurationMinutes(duration.minutes)),
            trailing: duration == current
                ? Icon(Icons.check, color: scheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(duration),
          ),
      ],
    );
  }
}

// ── Weekday labels ────────────────────────────────────────────────────────────

String _weekdayLabel(QuranSessionsLocalizations l10n, Weekday day) =>
    switch (day) {
      Weekday.saturday => l10n.weekdaySaturday,
      Weekday.sunday => l10n.weekdaySunday,
      Weekday.monday => l10n.weekdayMonday,
      Weekday.tuesday => l10n.weekdayTuesday,
      Weekday.wednesday => l10n.weekdayWednesday,
      Weekday.thursday => l10n.weekdayThursday,
      Weekday.friday => l10n.weekdayFriday,
    };

/// Day chips use the same labels — Arabic weekday names are already short.
String _weekdayShort(QuranSessionsLocalizations l10n, Weekday day) =>
    _weekdayLabel(l10n, day);
