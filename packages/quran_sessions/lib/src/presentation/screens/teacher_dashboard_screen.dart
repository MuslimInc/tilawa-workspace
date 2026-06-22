import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';

import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_availability.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_dashboard/teacher_dashboard_bloc.dart';
import '../blocs/teacher_dashboard/teacher_dashboard_event.dart';
import '../blocs/teacher_dashboard/teacher_dashboard_state.dart';
import '../widgets/date_grouped_slots_layout.dart';
import '../widgets/session_card.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({
    super.key,
    required this.teacherId,
    this.onManageSchedule,
  });

  final String teacherId;

  /// Opens the recurring weekly availability editor. Wired by the host router;
  /// when null the schedule entry points are hidden.
  final VoidCallback? onManageSchedule;

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String? _lastUndoSnackSlotId;
  final Set<String> _enterAnimatedSlotIds = {};

  static const _undoSnackDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    context.read<TeacherDashboardBloc>().add(
      TeacherDashboardLoadRequested(teacherId: widget.teacherId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacherDashboardTitle),
        actions: [
          if (widget.onManageSchedule != null)
            IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              tooltip: l10n.availabilityTitle,
              onPressed: widget.onManageSchedule,
            ),
        ],
      ),
      body: BlocConsumer<TeacherDashboardBloc, TeacherDashboardState>(
        listener: (context, state) {
          if (state is! TeacherDashboardSuccess) {
            _lastUndoSnackSlotId = null;
            return;
          }

          if (state.slotFailure != null) {
            TilawaFeedback.showToast(
              context,
              message: state.slotFailure!.toLocalizedMessage(context),
              variant: TilawaFeedbackVariant.error,
            );
          }

          final undoId = state.undoableSlotId;
          if (undoId == null) {
            _lastUndoSnackSlotId = null;
            return;
          }
          if (undoId == _lastUndoSnackSlotId) return;

          final pending = state.pendingDeletes[undoId];
          if (pending == null) return;

          _lastUndoSnackSlotId = undoId;
          _showDeleteUndoToast(context, pending.snapshot);
        },
        builder: (context, state) => switch (state) {
          TeacherDashboardInitial() || TeacherDashboardLoading() =>
            const Center(child: CircularProgressIndicator()),
          TeacherDashboardEmpty() => Center(
            child: Padding(
              padding: EdgeInsets.all(Theme.of(context).tokens.spaceLarge),
              child: TilawaEmptyState(
                icon: Icons.event_available_outlined,
                title: l10n.availabilitySetupHeadline,
                subtitle:
                    '${l10n.availabilitySetupBenefitRecurring}  ·  '
                    '${l10n.availabilitySetupBenefitTimezone}  ·  '
                    '${l10n.availabilitySetupBenefitSelfBooking}',
                action: TilawaButton(
                  text: l10n.availabilitySetupCta,
                  leadingIcon: const Icon(Icons.calendar_month_outlined),
                  onPressed: widget.onManageSchedule,
                ),
              ),
            ),
          ),
          TeacherDashboardFailure(:final failure) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure.toLocalizedMessage(context)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _reload,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
          TeacherDashboardSuccess(
            :final upcomingSessions,
            :final availability,
            :final isUpdatingAvailability,
          ) =>
            RefreshIndicator(
              onRefresh: () async => _reload(),
              child: CustomScrollView(
                slivers: [
                  // ── Upcoming sessions ──────────────────────────────────
                  _SectionHeader(
                    title: l10n.upcomingSessionsSection(
                      upcomingSessions.length,
                    ),
                  ),
                  if (upcomingSessions.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.noUpcomingSessions),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: upcomingSessions.length,
                      itemBuilder: (_, i) =>
                          SessionCard(session: upcomingSessions[i]),
                    ),

                  // ── Open slots ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            l10n.openSlotsSection(availability.length),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (isUpdatingAvailability) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                          const Spacer(),
                          if (widget.onManageSchedule != null)
                            TextButton.icon(
                              icon: const Icon(Icons.edit_calendar_outlined),
                              label: Text(l10n.availabilityTitle),
                              onPressed: widget.onManageSchedule,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (availability.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.noOpenSlots),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final tokens = Theme.of(context).tokens;
                          return DateGroupedSlotsLayout(
                            slots: availability,
                            padding: EdgeInsetsDirectional.only(
                              start: tokens.spaceLarge,
                              end: tokens.spaceLarge,
                            ),
                            slotsForDayBuilder: (context, daySlots) => Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    tokens.spaceExtraLarge * 2 +
                                    MediaQuery.paddingOf(context).bottom,
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0; i < daySlots.length; i++)
                                    _buildSlotTile(
                                      context,
                                      daySlots[i],
                                      showDivider: i < daySlots.length - 1,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
        },
      ),
    );
  }

  Widget _buildSlotTile(
    BuildContext context,
    TeacherAvailability slot, {
    required bool showDivider,
  }) {
    final tile = _SlotTile(
      slot: slot,
      timeOnly: true,
      showDivider: showDivider,
      onRemove: () => context.read<TeacherDashboardBloc>().add(
        AvailabilitySlotRemoved(teacherId: widget.teacherId, slot: slot),
      ),
    );

    if (!_enterAnimatedSlotIds.contains(slot.slotId)) return tile;

    return _EnterAnimatedSlotTile(
      key: ValueKey('enter-${slot.slotId}'),
      onComplete: () {
        if (mounted) {
          setState(() => _enterAnimatedSlotIds.remove(slot.slotId));
        }
      },
      child: tile,
    );
  }

  void _showDeleteUndoToast(
    BuildContext context,
    TeacherAvailability slot,
  ) {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final timeFmt = DateFormat('EEE d MMM، h:mm a', locale);
    final timeLabel = timeFmt.format(slot.startsAt.toLocal());

    TilawaFeedback.showActionable(
      context,
      message: l10n.deleteSlotRemovedSnackBar(timeLabel),
      variant: TilawaFeedbackVariant.success,
      duration: _undoSnackDuration,
      dedupeKey: 'teacher-dashboard-slot-undo',
      actions: <TilawaFeedbackAction>[
        TilawaFeedbackAction(
          label: l10n.deleteSlotUndo,
          onPressed: () {
            final current = context.read<TeacherDashboardBloc>().state;
            if (current is! TeacherDashboardSuccess) return;
            final undoId = current.undoableSlotId;
            if (undoId == null) return;

            setState(() => _enterAnimatedSlotIds.add(undoId));
            context.read<TeacherDashboardBloc>().add(
              AvailabilitySlotDeleteUndone(slotId: undoId),
            );
          },
        ),
      ],
    );
  }

  void _reload() => context.read<TeacherDashboardBloc>().add(
    TeacherDashboardLoadRequested(teacherId: widget.teacherId),
  );
}

// ── Enter animation (undo restore only; removal is instant) ───────────────────

class _EnterAnimatedSlotTile extends StatefulWidget {
  const _EnterAnimatedSlotTile({
    super.key,
    required this.child,
    required this.onComplete,
  });

  final Widget child;
  final VoidCallback onComplete;

  @override
  State<_EnterAnimatedSlotTile> createState() => _EnterAnimatedSlotTileState();
}

class _EnterAnimatedSlotTileState extends State<_EnterAnimatedSlotTile>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..forward().whenComplete(widget.onComplete);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        alignment: Alignment.topCenter,
        child: widget.child,
      ),
    );
  }
}

// ── Slot tile ─────────────────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.onRemove,
    this.timeOnly = false,
    this.showDivider = true,
  });

  final TeacherAvailability slot;
  final bool timeOnly;
  final VoidCallback onRemove;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('EEE d MMM، h:mm a', locale);
    final timeFmt = DateFormat('h:mm a', locale);
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final settingsTokens = Theme.of(context).componentTokens.settingsGroup;

    return TilawaCompactListRow(
      showDivider: showDivider,
      leading: Icon(
        slot.isBooked ? Icons.lock_outline : Icons.schedule,
        size: settingsTokens.tileIconSize,
        color: slot.isBooked ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: timeOnly
          ? timeFmt.format(slot.startsAt.toLocal())
          : dateFmt.format(slot.startsAt.toLocal()),
      subtitle: slot.isBooked ? l10n.slotBooked : l10n.slotAvailable,
      subtitleStyle: TextStyle(
        fontSize: settingsTokens.tileSubtitleFontSize,
        fontWeight: FontWeight.w500,
        color: slot.isBooked ? scheme.primary : scheme.tertiary,
        height: 1.2,
      ),
      trailing: slot.isBooked
          ? null
          : _DeleteSlotTrailing(
              onRemove: onRemove,
              deleteTooltip: l10n.deleteSlot,
              minInteractiveDimension: tokens.minInteractiveDimension,
              iconSizeSmall: tokens.iconSizeSmall,
            ),
    );
  }
}

class _DeleteSlotTrailing extends StatelessWidget {
  const _DeleteSlotTrailing({
    required this.onRemove,
    required this.deleteTooltip,
    required this.minInteractiveDimension,
    required this.iconSizeSmall,
  });

  final VoidCallback onRemove;
  final String deleteTooltip;
  final double minInteractiveDimension;
  final double iconSizeSmall;

  static const _visualDensity = VisualDensity.compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: deleteTooltip,
      onPressed: onRemove,
      visualDensity: _visualDensity,
      constraints: BoxConstraints.tightFor(
        width: minInteractiveDimension,
        height: minInteractiveDimension,
      ),
      padding: EdgeInsets.zero,
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
