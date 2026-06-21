import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_availability.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_dashboard/teacher_dashboard_bloc.dart';
import '../blocs/teacher_dashboard/teacher_dashboard_event.dart';
import '../blocs/teacher_dashboard/teacher_dashboard_state.dart';
import '../widgets/session_card.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key, required this.teacherId});

  final String teacherId;

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
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المعلم')),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد جلسات أو مواعيد بعد',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('أضف موعداً متاحاً'),
                  onPressed: _showAddSlotSheet,
                ),
              ],
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
                  child: const Text('إعادة المحاولة'),
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
                    title: 'الجلسات القادمة (${upcomingSessions.length})',
                  ),
                  if (upcomingSessions.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('لا توجد جلسات قادمة'),
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
                            'المواعيد المفتوحة (${availability.length})',
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
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: 'أضف موعداً',
                            onPressed: isUpdatingAvailability
                                ? null
                                : _showAddSlotSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (availability.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('لا توجد مواعيد مفتوحة'),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: availability.length,
                      itemBuilder: (_, i) {
                        final slot = availability[i];
                        return _SlotTile(
                          slot: slot,
                          isUpdating: isUpdatingAvailability,
                          onEdit: () => _showEditSlotSheet(slot),
                          onRemove: () =>
                              context.read<TeacherDashboardBloc>().add(
                                AvailabilitySlotRemoved(slotId: slot.slotId),
                              ),
                        );
                      },
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

  Future<void> _showAddSlotSheet() async {
    final slot = await showModalBottomSheet<TeacherAvailability>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSlotSheet(teacherId: widget.teacherId),
    );
    if (slot != null && mounted) {
      context.read<TeacherDashboardBloc>().add(
        AvailabilitySlotAdded(slot: slot),
      );
    }
  }

  Future<void> _showEditSlotSheet(TeacherAvailability original) async {
    final updated = await showModalBottomSheet<TeacherAvailability>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSlotSheet(
        teacherId: widget.teacherId,
        initialDate: original.startsAt,
        initialTime: TimeOfDay(
          hour: original.startsAt.hour,
          minute: original.startsAt.minute,
        ),
      ),
    );
    if (updated != null && mounted) {
      context.read<TeacherDashboardBloc>().add(
        AvailabilitySlotEdited(original: original, updated: updated),
      );
    }
  }
}

// ── Slot tile ─────────────────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.isUpdating,
    required this.onEdit,
    required this.onRemove,
  });

  final TeacherAvailability slot;
  final bool isUpdating;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE d MMM، h:mm a', 'ar');
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        slot.isBooked ? Icons.lock_outline : Icons.schedule,
        color: slot.isBooked ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(dateFmt.format(slot.startsAt.toLocal())),
      subtitle: Text(
        slot.isBooked ? 'محجوز' : 'متاح',
        style: TextStyle(
          color: slot.isBooked ? scheme.primary : scheme.tertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: slot.isBooked
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'تعديل الموعد',
                  onPressed: isUpdating ? null : onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'حذف الموعد',
                  onPressed: isUpdating ? null : onRemove,
                ),
              ],
            ),
    );
  }
}

// ── Add slot bottom sheet ─────────────────────────────────────────────────────

class _AddSlotSheet extends StatefulWidget {
  const _AddSlotSheet({
    required this.teacherId,
    this.initialDate,
    this.initialTime,
  });

  final String teacherId;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedTime = widget.initialTime ?? const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE، d MMMM y', 'ar');
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'إضافة موعد جديد',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          // Date picker row
          TilawaReadOnlyField(
            prefixIcon: Icons.calendar_today_outlined,
            semanticLabel: 'تاريخ الموعد',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Text(
              dateFmt.format(_selectedDate),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 12),
          // Time picker row
          TilawaReadOnlyField(
            prefixIcon: Icons.access_time,
            semanticLabel: 'وقت الموعد',
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
            child: Text(
              _selectedTime.format(context),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _confirm,
            child: const Text('إضافة الموعد'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final slot = TeacherAvailability(
      slotId: 'teacher_slot_${DateTime.now().millisecondsSinceEpoch}',
      teacherId: widget.teacherId,
      startsAt: start,
      endsAt: start.add(const Duration(hours: 1)),
      isBooked: false,
    );

    Navigator.pop(context, slot);
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
