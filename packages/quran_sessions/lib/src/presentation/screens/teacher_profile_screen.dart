import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_profile/teacher_profile_bloc.dart';
import '../blocs/teacher_profile/teacher_profile_event.dart';
import '../blocs/teacher_profile/teacher_profile_state.dart';
import '../widgets/availability_slot_picker.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    context.read<TeacherProfileBloc>().add(
      TeacherProfileRequested(
        teacherId: widget.teacherId,
        availabilityFrom: now,
        availabilityTo: now.add(const Duration(days: 7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Profile')),
      body: BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
        builder: (context, state) => switch (state) {
          TeacherProfileInitial() || TeacherProfileLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          TeacherProfileFailure(:final failure) => Center(
            child: Text(failure.toLocalizedMessage(context)),
          ),
          TeacherProfileSuccess(
            :final teacher,
            :final availability,
            :final reviews,
            :final isLoadingAvailability,
          ) =>
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Bio ─────────────────────────────────────────────────
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(teacher.avatarUrl),
                ),
                const SizedBox(height: 12),
                Text(
                  teacher.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '★ ${teacher.averageRating.toStringAsFixed(1)}'
                  ' · ${teacher.totalReviews} reviews',
                ),
                const SizedBox(height: 8),
                Text(teacher.bio),
                const Divider(height: 32),

                // ── Availability ─────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Available slots',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isLoadingAvailability) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                AvailabilitySlotPicker(
                  slots: availability,
                  selectedSlotId: null,
                  onSlotSelected: (slot) => _onBookTapped(slot.slotId),
                ),
                const Divider(height: 32),

                // ── Reviews ──────────────────────────────────────────────
                Text(
                  'Reviews',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (reviews.isEmpty)
                  const Text('No reviews yet')
                else
                  ...reviews.map(
                    (r) => ListTile(
                      leading: Text('${r.rating}★'),
                      title: Text(r.comment ?? ''),
                      dense: true,
                    ),
                  ),
              ],
            ),
        },
      ),
      floatingActionButton:
          BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
            builder: (context, state) => state is TeacherProfileSuccess
                ? FloatingActionButton.extended(
                    label: const Text('Book Session'),
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () => _onBookTapped(null),
                  )
                : const SizedBox.shrink(),
          ),
    );
  }

  void _onBookTapped(String? preSelectedSlotId) {
    // Host app navigates to BookingScreen via QuranSessionsRoutes.booking.
  }
}
