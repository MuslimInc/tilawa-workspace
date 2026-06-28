import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/entities/session_review.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/value_objects/teacher_public_name.dart';
import '../config/quran_sessions_analytics_callbacks.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_profile/teacher_profile_bloc.dart';
import '../blocs/teacher_profile/teacher_profile_event.dart';
import '../blocs/teacher_profile/teacher_profile_state.dart';
import '../theme/quran_sessions_status_colors.dart';
import '../widgets/availability_slot_picker.dart';
import '../widgets/paid_session_notice.dart';
import '../widgets/quran_session_price_chip.dart';
import '../widgets/quran_sessions_scaffold.dart';
import '../widgets/quran_sessions_section_header.dart';
import '../widgets/report_concern_sheet.dart';
import '../widgets/teacher_credentials_section.dart';
import '../widgets/teacher_discovery_details.dart';
import '../widgets/teacher_initials_avatar.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({
    super.key,
    required this.teacherId,
    this.analytics = const QuranSessionsAnalyticsCallbacks(),
    this.onBookTapped,
    this.bookingEnabled = true,
  });

  final String teacherId;
  final QuranSessionsAnalyticsCallbacks analytics;

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
    widget.analytics.onTeacherProfileViewed?.call(widget.teacherId);
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
      actions: [
        BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
          builder: (context, state) {
            if (state is! TeacherProfileSuccess ||
                !_isTeacherMarketplaceVisible(state.teacher)) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: l10n.reportTutorAction,
              onPressed: state.reportInProgress
                  ? null
                  : () => _submitReport(context),
              icon: const Icon(Icons.flag_outlined),
            );
          },
        ),
      ],
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
                  child: TilawaButton(
                    text: canBook
                        ? l10n.bookSessionAction
                        : l10n.noAvailabilityBookAction,
                    onPressed: canBook
                        ? () => _onBookTapped(_selectedSlotId)
                        : null,
                    leadingIcon: const Icon(Icons.calendar_today_outlined),
                    size: TilawaButtonSize.large,
                    isFullWidth: true,
                  ),
                );
              },
            )
          : null,
      body: MultiBlocListener(
        listeners: [
          BlocListener<TeacherProfileBloc, TeacherProfileState>(
            listenWhen: (previous, current) =>
                current is TeacherProfileSuccess &&
                ((previous is! TeacherProfileSuccess) ||
                    previous.reportFailure != current.reportFailure ||
                    previous.reportSubmitted != current.reportSubmitted),
            listener: (context, state) {
              if (state is! TeacherProfileSuccess) return;
              if (state.reportFailure != null) {
                TilawaFeedback.showToast(
                  context,
                  message: state.reportFailure!.toLocalizedMessage(context),
                  variant: TilawaFeedbackVariant.error,
                );
              }
              if (state.reportSubmitted) {
                TilawaFeedback.showToast(
                  context,
                  message: l10n.reportConcernSubmitted,
                  variant: TilawaFeedbackVariant.success,
                );
                context.read<TeacherProfileBloc>().add(
                  const TeacherProfileReportAcknowledged(),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
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
      ),
    );
  }

  Future<void> _submitReport(BuildContext context) async {
    final input = await showReportConcernSheet(context);
    if (input == null || !context.mounted) return;
    context.read<TeacherProfileBloc>().add(
      TeacherProfileReportSubmitted(
        category: input.category,
        description: input.description,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.quranSessionsStatus;
    final tokens = Theme.of(context).tokens;
    final displayName = widget.teacher.displayName.trim();
    final bio = widget.teacher.bio.trim();

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      children: [
        TilawaCard(
          padding: EdgeInsets.all(tokens.spaceSmall),
          child: Column(
            children: [
              TeacherInitialsAvatar(
                displayName: displayName,
                radius: tokens.iconSizeLarge,
                avatarUrl: widget.teacher.avatarUrl,
              ),
              SizedBox(height: tokens.spaceSmall),
              Text(
                displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.teacher.isVerified) ...[
                SizedBox(height: tokens.spaceExtraSmall),
                Center(
                  child: TilawaVerifiedTeacherBadge(
                    label: l10n.verifiedTeacherBadge,
                  ),
                ),
              ],
              SizedBox(height: tokens.spaceExtraSmall),
              _TeacherProfileRatingRow(
                rating: widget.teacher.averageRating,
                reviewsCount: widget.teacher.totalReviews,
              ),
              SizedBox(height: tokens.spaceSmall),
              TeacherDiscoveryDetails(teacher: widget.teacher),
              SizedBox(height: tokens.spaceExtraSmall),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QuranSessionPriceChip(teacher: widget.teacher),
                    for (final code in widget.teacher.specializations) ...[
                      SizedBox(width: tokens.spaceExtraSmall),
                      TilawaMetadataChip(
                        label: l10n.specializationLabel(code),
                      ),
                    ],
                    if (widget.teacher.supportedCallTypes.contains(
                      SessionCallType.externalMeeting,
                    )) ...[
                      SizedBox(width: tokens.spaceExtraSmall),
                      TilawaMetadataChip(
                        label: l10n.teacherOffersExternalSessions,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.teacher.manualPaymentPrice case final manualPrice?) ...[
          SizedBox(height: tokens.spaceSmall),
          PaidSessionNotice(price: manualPrice),
        ],
        if (bio.isNotEmpty) ...[
          SizedBox(height: tokens.spaceSmall),
          QuranSessionsSectionHeader(title: l10n.aboutTeacherSection),
          SizedBox(height: tokens.spaceExtraSmall),
          TilawaCard(
            padding: EdgeInsets.all(tokens.spaceSmall),
            child: Text(
              bio,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
        SizedBox(height: tokens.spaceSmall),
        TeacherCredentialsSection(credentials: widget.teacher.credentials),
        SizedBox(height: tokens.spaceSmall),
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
        SizedBox(height: tokens.spaceExtraSmall),
        TilawaCard(
          padding: EdgeInsets.all(tokens.spaceSmall),
          child: widget.availability.isEmpty && !widget.isLoadingAvailability
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.noAvailabilityYet,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    Text(
                      l10n.noAvailabilityHelper,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
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
        SizedBox(height: tokens.spaceSmall),
        QuranSessionsSectionHeader(title: l10n.reviewsSection),
        SizedBox(height: tokens.spaceExtraSmall),
        TilawaCard(
          padding: EdgeInsets.all(tokens.spaceSmall),
          child: widget.reviews.isEmpty
              ? Text(
                  l10n.noReviewsYet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                )
              : Column(
                  children: widget.reviews
                      .map(
                        (r) => Padding(
                          padding: EdgeInsets.only(
                            bottom: tokens.spaceExtraSmall,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.rating}★',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: status.rating,
                                ),
                              ),
                              SizedBox(width: tokens.spaceSmall),
                              Expanded(
                                child: Text(
                                  r.comment ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.quranSessionsStatus;
    final tokens = Theme.of(context).tokens;
    final isNew = reviewsCount == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.star_rounded,
          size: tokens.iconSizeSmall,
          color: status.rating,
        ),
        SizedBox(width: tokens.spaceExtraSmall),
        Text(
          isNew
              ? l10n.teacherNewRating
              : l10n.teacherRatingReviews(
                  rating.toStringAsFixed(1),
                  reviewsCount,
                ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
