import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../../utils/price_formatter.dart';
import '../../utils/specialization_labels.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_profile/teacher_profile_bloc.dart';
import '../blocs/teacher_profile/teacher_profile_event.dart';
import '../blocs/teacher_profile/teacher_profile_state.dart';
import '../widgets/availability_slot_picker.dart';
import '../widgets/teacher_initials_avatar.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({
    super.key,
    required this.teacherId,
    this.onBookTapped,
  });

  final String teacherId;

  /// Called when the user initiates a booking. The host app navigates to
  /// [BookingScreen] with [teacherId] and the optional pre-selected [slotId].
  final void Function(String teacherId, String? slotId)? onBookTapped;

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    context.read<TeacherProfileBloc>().add(
      TeacherProfileRequested(
        teacherId: widget.teacherId,
        availabilityFrom: now,
        availabilityTo: now.add(const Duration(days: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملف المعلم')),
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
                // ── Hero ────────────────────────────────────────────────
                Center(
                  child: TeacherInitialsAvatar(
                    displayName: teacher.displayName,
                    radius: 44,
                    avatarUrl: teacher.avatarUrl,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    teacher.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${teacher.averageRating.toStringAsFixed(1)} · ${teacher.totalReviews} تقييم',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── Pricing ──────────────────────────────────────────────
                Center(child: _PricingRow(teacher: teacher)),
                const SizedBox(height: 10),
                // ── Specializations ──────────────────────────────────────
                if (teacher.specializations.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: teacher.specializations.map((code) {
                      return Chip(
                        label: Text(SpecializationLabels.arabic(code)),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                Text(teacher.bio),
                const Divider(height: 32),

                // ── Availability ─────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'المواعيد المتاحة',
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
                const SizedBox(height: 12),
                AvailabilitySlotPicker(
                  slots: availability,
                  selectedSlotId: _selectedSlotId,
                  onSlotSelected: (slot) {
                    setState(() => _selectedSlotId = slot.slotId);
                    _onBookTapped(slot.slotId);
                  },
                ),
                const Divider(height: 32),

                // ── Reviews ──────────────────────────────────────────────
                Text(
                  'التقييمات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (reviews.isEmpty)
                  const Text('لا توجد تقييمات بعد')
                else
                  ...reviews.map(
                    (r) => ListTile(
                      leading: Text('${r.rating}★'),
                      title: Text(r.comment ?? ''),
                      dense: true,
                    ),
                  ),
                // Extra space for FAB
                const SizedBox(height: 80),
              ],
            ),
        },
      ),
      floatingActionButton:
          BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
            builder: (context, state) => state is TeacherProfileSuccess
                ? FloatingActionButton.extended(
                    label: const Text('احجز جلسة'),
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () => _onBookTapped(null),
                  )
                : const SizedBox.shrink(),
          ),
    );
  }

  void _onBookTapped(String? preSelectedSlotId) {
    widget.onBookTapped?.call(widget.teacherId, preSelectedSlotId);
  }
}

// ── Pricing row ───────────────────────────────────────────────────────────────

class _PricingRow extends StatelessWidget {
  const _PricingRow({required this.teacher});

  final QuranTeacher teacher;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFree = teacher.pricingType == SessionPricingType.free;
    final label = PriceFormatter.formatOrFree(
      pricingType: teacher.pricingType,
      price: teacher.price,
    );

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isFree ? scheme.secondaryContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isFree
              ? scheme.onSecondaryContainer
              : scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
