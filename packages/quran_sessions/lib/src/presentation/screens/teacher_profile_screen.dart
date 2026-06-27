import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/entities/session_review.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/value_objects/teacher_public_name.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_profile/teacher_profile_bloc.dart';
import '../blocs/teacher_profile/teacher_profile_event.dart';
import '../blocs/teacher_profile/teacher_profile_state.dart';
import '../theme/quran_sessions_theme.dart';
import '../widgets/availability_slot_picker.dart';
import '../widgets/quran_session_price_chip.dart';
import '../widgets/quran_sessions_metadata_chip.dart';
import '../widgets/quran_sessions_scaffold.dart';
import '../widgets/quran_sessions_section_header.dart';
import '../widgets/quran_sessions_surface_card.dart';
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

    return QuranSessionsScaffold(
      title: l10n.teacherProfileTitle,
      bottomNavigationBar: widget.bookingEnabled && widget.onBookTapped != null
          ? BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
              builder: (context, state) {
                if (state is! TeacherProfileSuccess ||
                    !_isTeacherMarketplaceVisible(state.teacher)) {
                  return const SizedBox.shrink();
                }
                final canBook =
                    !state.isLoadingAvailability &&
                    state.availability.isNotEmpty;
                return TilawaBottomActionArea(
                  child: _TeacherProfileBookingCta(
                    label: canBook
                        ? l10n.bookSessionAction
                        : l10n.noAvailabilityBookAction,
                    enabled: canBook,
                    onPressed: canBook
                        ? () => _onBookTapped(_selectedSlotId)
                        : null,
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

class _TeacherProfileBookingCta extends StatelessWidget {
  const _TeacherProfileBookingCta({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final background = enabled
        ? feature.primaryColor
        : feature.disabledBackground;
    final foreground = enabled
        ? feature.onPrimaryColor
        : feature.disabledForeground;
    final border = enabled ? feature.primaryColor : feature.disabledBorder;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: double.infinity,
        minHeight: tokens.minInteractiveDimension,
      ),
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLarge,
              vertical: tokens.spaceSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: tokens.iconSizeMedium,
                  color: foreground,
                ),
                SizedBox(width: tokens.spaceSmall),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: feature.sectionTitleStyle.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final displayName = widget.teacher.displayName.trim();
    final bio = widget.teacher.bio.trim();

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: feature.screenPaddingHorizontal,
        vertical: feature.sectionGap,
      ),
      children: [
        QuranSessionsSurfaceCard(
          child: Column(
            children: [
              TeacherInitialsAvatar(
                displayName: displayName,
                radius: feature.profileAvatarRadius,
                avatarUrl: widget.teacher.avatarUrl,
              ),
              SizedBox(height: feature.sectionGap),
              Text(
                displayName,
                style: feature.sectionTitleStyle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: feature.listItemGap),
              _TeacherProfileRatingRow(
                rating: widget.teacher.averageRating,
                reviewsCount: widget.teacher.totalReviews,
              ),
              SizedBox(height: feature.listItemGap),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QuranSessionPriceChip(teacher: widget.teacher),
                    for (final code in widget.teacher.specializations) ...[
                      SizedBox(width: feature.listItemGap),
                      QuranSessionsMetadataChip(
                        label: l10n.specializationLabel(code),
                      ),
                    ],
                    if (widget.teacher.supportedCallTypes.contains(
                      SessionCallType.externalMeeting,
                    )) ...[
                      SizedBox(width: feature.listItemGap),
                      QuranSessionsMetadataChip(
                        label: l10n.teacherOffersExternalSessions,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (bio.isNotEmpty) ...[
          SizedBox(height: feature.sectionGap),
          QuranSessionsSectionHeader(title: l10n.aboutTeacherSection),
          SizedBox(height: feature.listItemGap),
          QuranSessionsSurfaceCard(
            child: Text(bio, style: feature.screenSubtitleStyle),
          ),
        ],
        SizedBox(height: feature.sectionGap),
        QuranSessionsSectionHeader(
          title: l10n.availableSlots,
          trailing: widget.isLoadingAvailability
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        SizedBox(height: feature.listItemGap),
        QuranSessionsSurfaceCard(
          child: widget.availability.isEmpty && !widget.isLoadingAvailability
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.noAvailabilityYet,
                      style: feature.cardTitleStyle,
                    ),
                    SizedBox(height: feature.listItemGap),
                    Text(
                      l10n.noAvailabilityHelper,
                      style: feature.cardMetaStyle,
                    ),
                  ],
                )
              : AvailabilitySlotPicker(
                  slots: widget.availability,
                  selectedSlotId: widget.selectedSlotId,
                  onSlotSelected: (slot) {
                    widget.onSlotSelected?.call(slot.slotId);
                  },
                ),
        ),
        SizedBox(height: feature.sectionGap),
        QuranSessionsSectionHeader(title: l10n.reviewsSection),
        SizedBox(height: feature.listItemGap),
        QuranSessionsSurfaceCard(
          child: widget.reviews.isEmpty
              ? Text(
                  l10n.noReviewsYet,
                  style: feature.cardMetaStyle,
                )
              : Column(
                  children: widget.reviews
                      .map(
                        (r) => Padding(
                          padding: EdgeInsets.only(
                            bottom: feature.listItemGap,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.rating}★',
                                style: feature.chipLabelStyle.copyWith(
                                  color: feature.ratingColor,
                                ),
                              ),
                              SizedBox(width: feature.cardGap),
                              Expanded(
                                child: Text(
                                  r.comment ?? '',
                                  style: feature.cardMetaStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        SizedBox(height: tokens.spaceExtraLarge * 2),
      ],
    );
  }
}

class _TeacherProfileRatingRow extends StatelessWidget {
  const _TeacherProfileRatingRow({
    required this.rating,
    required this.reviewsCount,
  });

  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final isNew = reviewsCount == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.star_rounded,
          size: tokens.iconSizeSmall,
          color: feature.ratingColor,
        ),
        SizedBox(width: tokens.spaceExtraSmall),
        Text(
          isNew
              ? l10n.teacherNewRating
              : l10n.teacherRatingReviews(
                  rating.toStringAsFixed(1),
                  reviewsCount,
                ),
          style: feature.cardMetaStyle,
        ),
      ],
    );
  }
}
