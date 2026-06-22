import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/availability_override.dart';
import '../../domain/entities/availability_override_group.dart';
import '../../domain/entities/slot_duration.dart';
import '../../domain/entities/weekday.dart';
import '../blocs/availability/availability_cubit.dart';
import '../blocs/availability/availability_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/availability_day_hours_row.dart';
import '../widgets/availability_override_sheet.dart';
import '../widgets/availability_vacation_dialogs.dart';
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

  int _heardSaveTick = 0;
  int _heardOverrideAddTick = 0;
  int _heardOverrideRemoveTick = 0;

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
    final state = context.watch<AvailabilityCubit>().state;
    final canPop = state.status != AvailabilityStatus.ready || !state.isDirty;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final current = context.read<AvailabilityCubit>().state;
        if (!current.isDirty) {
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        final discard = await _confirmDiscard(context);
        if (discard && context.mounted) {
          context.read<AvailabilityCubit>().discardChanges();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
              prev.saveTick != curr.saveTick ||
              prev.overrideAddTick != curr.overrideAddTick ||
              prev.overrideRemoveTick != curr.overrideRemoveTick ||
              prev.failure != curr.failure,
          listener: (context, state) {
            if (state.saveTick > _heardSaveTick && state.failure == null) {
              _heardSaveTick = state.saveTick;
              TilawaFeedback.showToast(
                context,
                message: l10n.availabilitySavedToast,
                variant: TilawaFeedbackVariant.success,
              );
            }
            if (state.overrideAddTick > _heardOverrideAddTick &&
                state.failure == null) {
              _heardOverrideAddTick = state.overrideAddTick;
              TilawaFeedback.showToast(
                context,
                message: l10n.availabilityOverrideAddedToast,
                variant: TilawaFeedbackVariant.success,
              );
            }
            if (state.overrideRemoveTick > _heardOverrideRemoveTick &&
                state.failure == null) {
              _heardOverrideRemoveTick = state.overrideRemoveTick;
              TilawaFeedback.showToast(
                context,
                message: l10n.availabilityOverrideRemovedToast,
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
      ),
    );
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
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
    return discard == true;
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
                  onPressed: state.saveEnabled
                      ? () => context.read<AvailabilityCubit>().save()
                      : null,
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
    final discard = await _confirmDiscard(context);
    if (discard && context.mounted) {
      context.read<AvailabilityCubit>().discardChanges();
      Navigator.of(context).pop();
    }
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
        _RecurringAvailabilityBanner(message: l10n.availabilityRecurringBanner),
        SizedBox(height: tokens.spaceLarge),
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
          AvailabilityDayHoursRow(
            label: l10n.availabilityHoursRow,
            ranges: draft.rangesFor(openDays.first),
            onAddRange: () => _addRange(context, openDays.first),
            onEditRange: (index) => _editRange(context, openDays.first, index),
            onRemoveRange: (index) =>
                context.read<AvailabilityCubit>().removeRange(
                  openDays.first,
                  index,
                ),
          )
        else
          for (final day in openDays) ...[
            AvailabilityDayHoursRow(
              label: _weekdayLabel(l10n, day),
              ranges: draft.rangesFor(day),
              onAddRange: () => _addRange(context, day),
              onEditRange: (index) => _editRange(context, day, index),
              onRemoveRange: (index) =>
                  context.read<AvailabilityCubit>().removeRange(day, index),
            ),
            SizedBox(height: tokens.spaceSmall),
          ],
      ],
    );
  }

  Future<void> _pickTimezone(BuildContext context) async {
    final cubit = context.read<AvailabilityCubit>();
    final scheme = Theme.of(context).colorScheme;
    final selected = await showTilawaModalBottomSheet<String>(
      context: context,
      backgroundColor: scheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.75;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _TimezonePickerSheet(current: state.draft.timezone),
        );
      },
    );
    if (selected != null) cubit.setTimezone(selected);
  }

  Future<void> _pickDuration(BuildContext context) async {
    final cubit = context.read<AvailabilityCubit>();
    final scheme = Theme.of(context).colorScheme;
    final selected = await showTilawaModalBottomSheet<SlotDuration>(
      context: context,
      backgroundColor: scheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.75;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _DurationPickerSheet(current: state.draft.slotDuration),
        );
      },
    );
    if (selected != null) cubit.setDuration(selected);
  }

  Future<void> _addRange(BuildContext context, Weekday day) async {
    final cubit = context.read<AvailabilityCubit>();
    final ranges = state.draft.rangesFor(day);
    final range = await showTimeRangeEditorSheet(context, existing: ranges);
    if (range != null) cubit.addRange(day, range);
  }

  Future<void> _editRange(
    BuildContext context,
    Weekday day,
    int index,
  ) async {
    final cubit = context.read<AvailabilityCubit>();
    final ranges = state.draft.rangesFor(day);
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

// ── Day chips (Sat → Fri) ─────────────────────────────────────────────────────

class _RecurringAvailabilityBanner extends StatelessWidget {
  const _RecurringAvailabilityBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final bannerTokens = Theme.of(context).componentTokens.permissionBanner;

    return Container(
      padding: bannerTokens.padding,
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: tokens.iconSizeSmall,
            color: scheme.onTertiaryContainer,
          ),
          SizedBox(width: tokens.spaceSmall),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

// ── Day chips (Sat → Fri) ─────────────────────────────────────────────────────

class _OverridesTab extends StatelessWidget {
  const _OverridesTab({required this.state});

  final AvailabilityState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final material = MaterialLocalizations.of(context);

    final groups = groupAvailabilityOverrides(state.overrides);

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
                  itemCount: groups.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: tokens.spaceSmall),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final title = group.isSingleDay
                        ? material.formatMediumDate(group.start)
                        : '${material.formatMediumDate(group.start)} – '
                              '${material.formatMediumDate(group.end)}';
                    return _OverrideTile(
                      title: title,
                      subtitle: group.type == OverrideType.unavailable
                          ? l10n.availabilityOverrideUnavailable
                          : l10n.availabilityOverrideCustom,
                      isBusy: state.isOverridesBusy,
                      onRemove: () => _removeOverrideGroup(
                        context,
                        group: group,
                      ),
                    );
                  },
                ),
        ),
        TilawaBottomActionArea(
          showTopBorder: false,
          child: TilawaButton(
            text: l10n.availabilityAddOverride,
            isFullWidth: true,
            variant: TilawaButtonVariant.secondary,
            leadingIcon: const Icon(Icons.add),
            isLoading: state.isOverridesBusy,
            onPressed: state.isOverridesBusy
                ? null
                : () => _addOverride(context),
          ),
        ),
      ],
    );
  }

  Future<void> _addOverride(BuildContext context) async {
    final cubit = context.read<AvailabilityCubit>();
    final overrides = await showOverrideEditorSheet(
      context,
      existingOverrides: state.overrides,
    );
    if (overrides != null) await cubit.addOverrides(overrides);
  }

  Future<void> _removeOverrideGroup(
    BuildContext context, {
    required AvailabilityOverrideGroup group,
  }) async {
    if (group.type == OverrideType.unavailable) {
      final confirmed = await showDeleteVacationConfirmDialog(context);
      if (!confirmed || !context.mounted) return;
    }

    await context.read<AvailabilityCubit>().removeOverrides(group.dateKeys);
  }
}

class _OverrideTile extends StatelessWidget {
  const _OverrideTile({
    required this.title,
    required this.subtitle,
    required this.onRemove,
    this.isBusy = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRemove;
  final bool isBusy;

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
            onPressed: isBusy ? null : onRemove,
            icon: isBusy
                ? SizedBox(
                    width: Theme.of(context).tokens.iconSizeSmall,
                    height: Theme.of(context).tokens.iconSizeSmall,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.delete_outline),
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
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final tz = options[index];
              return ListTile(
                title: Text(tz),
                trailing: tz == current
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(tz),
              );
            },
          ),
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
        Expanded(
          child: ListView.builder(
            itemCount: SlotDuration.presets.length,
            itemBuilder: (context, index) {
              final duration = SlotDuration.presets[index];
              return ListTile(
                title: Text(l10n.availabilityDurationMinutes(duration.minutes)),
                trailing: duration == current
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(duration),
              );
            },
          ),
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
