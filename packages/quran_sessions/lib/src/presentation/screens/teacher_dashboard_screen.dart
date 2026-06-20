import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: BlocConsumer<TeacherDashboardBloc, TeacherDashboardState>(
        listener: (context, state) {
          if (state is TeacherDashboardSuccess && state.slotFailure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.slotFailure!.toLocalizedMessage(context)),
              ),
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
                const Text('No upcoming sessions or open slots yet.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add availability'),
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
                ElevatedButton(onPressed: _reload, child: const Text('Retry')),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'Upcoming sessions (${upcomingSessions.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  if (upcomingSessions.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('No upcoming sessions'),
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
                            'Open slots (${availability.length})',
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
                            tooltip: 'Add slot',
                            onPressed: isUpdatingAvailability
                                ? null
                                : _showAddSlotSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: availability.length,
                    itemBuilder: (_, i) {
                      final slot = availability[i];
                      return ListTile(
                        title: Text(slot.startsAt.toLocal().toString()),
                        subtitle: Text(slot.isBooked ? 'Booked' : 'Open'),
                        trailing: slot.isBooked
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remove slot',
                                onPressed: isUpdatingAvailability
                                    ? null
                                    : () => context
                                          .read<TeacherDashboardBloc>()
                                          .add(
                                            AvailabilitySlotRemoved(
                                              slotId: slot.slotId,
                                            ),
                                          ),
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

  void _showAddSlotSheet() {
    // Slot creation UI — placeholder until AddSlotSheet is implemented.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add slot — coming soon')),
    );
  }
}
