import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../../domain/entities/session_review.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../utils/price_formatter.dart';
import '../../domain/value_objects/teacher_public_name.dart';
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
    this.bookingEnabled = true,
  });

  final String teacherId;

  /// Called when the user initiates a booking. The host app navigates to
  /// [BookingScreen] with [teacherId] and the optional pre-selected [slotId].
  final void Function(String teacherId, String? slotId)? onBookTapped;

  /// When false, hides booking actions (marketplace booking not yet enabled).
  final bool bookingEnabled;

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
    final l10n = context.quranSessionsL10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teacherProfileTitle)),
      bottomNavigationBar: widget.bookingEnabled && widget.onBookTapped != null
          ? BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
              builder: (context, state) {
                if (state is! TeacherProfileSuccess ||
                    !_isTeacherMarketplaceVisible(state.teacher)) {
                  return const SizedBox.shrink();
                }
                return TilawaBottomActionArea(
                  child: TilawaButton(
                    text: l10n.bookSessionAction,
                    leadingIcon: const Icon(Icons.calendar_today_outlined),
                    isFullWidth: true,
                    size: TilawaButtonSize.large,
                    onPressed: () => _onBookTapped(_selectedSlotId),
                  ),
                );
              },
            )
          : null,
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
            _isTeacherMarketplaceVisible(teacher)
                ? _TeacherProfileBody(
                    teacher: teacher,
                    availability: availability,
                    reviews: reviews,
                    isLoadingAvailability: isLoadingAvailability,
                    bookingEnabled: widget.bookingEnabled,
                    onBookTapped: widget.onBookTapped == null
                        ? null
                        : (slotId) => _onBookTapped(slotId),
                    onSlotSelected: (slotId) =>
                        setState(() => _selectedSlotId = slotId),
                    selectedSlotId: _selectedSlotId,
                    teacherId: widget.teacherId,
                  )
                : _TeacherProfileUnavailableBody(),
        },
      ),
    );
  }

  void _onBookTapped(String? preSelectedSlotId) {
    widget.onBookTapped?.call(widget.teacherId, preSelectedSlotId);
  }
}

bool _isTeacherMarketplaceVisible(QuranTeacher teacher) {
  return ValidateTeacherPublicName.isValid(teacher.displayName) &&
      teacher.bio.trim().isNotEmpty &&
      teacher.isVerified;
}

class _TeacherProfileUnavailableBody extends StatelessWidget {
  const _TeacherProfileUnavailableBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: TilawaEmptyState(
          icon: Icons.person_off_outlined,
          title: l10n.teacherProfileUnavailableTitle,
          subtitle: l10n.teacherProfileUnavailableSubtitle,
        ),
      ),
    );
  }
}

class _TeacherProfileBody extends StatefulWidget {
  const _TeacherProfileBody({
    required this.teacher,
    required this.availability,
    required this.reviews,
    required this.isLoadingAvailability,
    required this.bookingEnabled,
    required this.teacherId,
    this.onBookTapped,
    this.onSlotSelected,
    this.selectedSlotId,
  });

  final QuranTeacher teacher;
  final List<TeacherAvailability> availability;
  final List<SessionReview> reviews;
  final bool isLoadingAvailability;
  final bool bookingEnabled;
  final String teacherId;
  final void Function(String? slotId)? onBookTapped;
  final ValueChanged<String>? onSlotSelected;
  final String? selectedSlotId;

  @override
  State<_TeacherProfileBody> createState() => _TeacherProfileBodyState();
}

class _TeacherProfileBodyState extends State<_TeacherProfileBody> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final displayName = widget.teacher.displayName.trim();
    final bio = widget.teacher.bio.trim();

    return ListView(
      padding: EdgeInsets.all(tokens.spaceMedium),
      children: [
        Center(
          child: TeacherInitialsAvatar(
            displayName: displayName,
            radius: 44,
            avatarUrl: widget.teacher.avatarUrl,
          ),
        ),
        SizedBox(height: tokens.spaceMedium),
        Center(
          child: Text(
            displayName,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: tokens.spaceExtraSmall),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              SizedBox(width: tokens.spaceExtraSmall),
              Text(
                l10n.teacherRatingReviews(
                  widget.teacher.averageRating.toStringAsFixed(1),
                  widget.teacher.totalReviews,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        Center(child: _PricingRow(teacher: widget.teacher)),
        if (widget.teacher.specializations.isNotEmpty) ...[
          SizedBox(height: tokens.spaceSmall),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: tokens.spaceSmall,
            runSpacing: tokens.spaceSmall,
            children: widget.teacher.specializations.map((code) {
              return TilawaStatusChip(label: l10n.specializationLabel(code));
            }).toList(),
          ),
        ],
        if (bio.isNotEmpty) ...[
          SizedBox(height: tokens.spaceMedium),
          Text(bio, textDirection: TextDirection.ltr),
        ],
        Divider(height: tokens.spaceExtraLarge),
        Row(
          children: [
            Text(
              l10n.availableSlots,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.isLoadingAvailability) ...[
              SizedBox(width: tokens.spaceSmall),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        SizedBox(height: tokens.spaceMedium),
        if (widget.availability.isEmpty && !widget.isLoadingAvailability)
          Text(
            l10n.noAvailabilityYet,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          AvailabilitySlotPicker(
            slots: widget.availability,
            selectedSlotId: widget.selectedSlotId,
            onSlotSelected: (slot) {
              widget.onSlotSelected?.call(slot.slotId);
              widget.onBookTapped?.call(slot.slotId);
            },
          ),
        Divider(height: tokens.spaceExtraLarge),
        Text(
          l10n.reviewsSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: tokens.spaceSmall),
        if (widget.reviews.isEmpty)
          Text(
            l10n.noReviewsYet,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...widget.reviews.map(
            (r) => ListTile(
              leading: Text('${r.rating}★'),
              title: Text(r.comment ?? ''),
              dense: true,
            ),
          ),
        SizedBox(height: tokens.spaceExtraLarge * 2),
      ],
    );
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
      l10n: context.quranSessionsL10n,
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
