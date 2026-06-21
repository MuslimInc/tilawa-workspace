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
          if (state is TeacherDashboardSuccess && state.slotFailure != null) {
            TilawaFeedback.showToast(
              context,
              message: state.slotFailure!.toLocalizedMessage(context),
              variant: TilawaFeedbackVariant.error,
            );
          }
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
                                    _SlotTile(
                                      slot: daySlots[i],
                                      timeOnly: true,
                                      isUpdating: isUpdatingAvailability,
                                      showDivider: i < daySlots.length - 1,
                                      onRemove: () => _confirmRemoveSlot(
                                        context,
                                        daySlots[i],
                                      ),
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

  void _reload() => context.read<TeacherDashboardBloc>().add(
    TeacherDashboardLoadRequested(teacherId: widget.teacherId),
  );

  Future<void> _confirmRemoveSlot(
    BuildContext context,
    TeacherAvailability slot,
  ) async {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('EEE d MMM', locale);
    final timeFmt = DateFormat('h:mm a', locale);
    final localStart = slot.startsAt.toLocal();
    final confirmed = await showTilawaFormDialog<bool>(
      context: context,
      title: l10n.deleteSlotConfirmTitle,
      primaryLabel: l10n.deleteSlotConfirm,
      primaryVariant: TilawaButtonVariant.danger,
      secondaryLabel: l10n.cancel,
      onPrimary: (dialogContext) => Navigator.of(dialogContext).pop(true),
      onSecondary: (dialogContext) => Navigator.of(dialogContext).pop(false),
      onClose: (dialogContext) => Navigator.of(dialogContext).pop(false),
      bodyBuilder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.slotDate}: ${dateFmt.format(localStart)}',
            style: Theme.of(dialogContext).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.slotTime}: ${timeFmt.format(localStart)}',
            style: Theme.of(dialogContext).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.deleteSlotConfirmMessage,
            style: Theme.of(dialogContext).textTheme.bodyLarge,
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    context.read<TeacherDashboardBloc>().add(
      AvailabilitySlotRemoved(teacherId: widget.teacherId, slot: slot),
    );
  }
}

// ── Slot tile ─────────────────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.isUpdating,
    required this.onRemove,
    this.timeOnly = false,
    this.showDivider = true,
  });

  final TeacherAvailability slot;
  final bool isUpdating;
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
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteSlot,
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints.tightFor(
                width: tokens.minInteractiveDimension,
                height: tokens.minInteractiveDimension,
              ),
              padding: EdgeInsets.zero,
              onPressed: isUpdating ? null : onRemove,
            ),
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
