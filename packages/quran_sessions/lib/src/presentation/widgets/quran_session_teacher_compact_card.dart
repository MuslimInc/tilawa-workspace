import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../models/teacher_availability_summary.dart';
import '../theme/quran_sessions_theme.dart';
import 'quran_session_price_chip.dart';
import 'quran_sessions_metadata_chip.dart';
import 'quran_sessions_surface_card.dart';
import 'teacher_initials_avatar.dart';

/// Single coherent teacher row for the discovery list.
///
/// One adaptive, [Directionality]-aware layout drives both Arabic (RTL) and
/// English (LTR): an avatar + identity column (name, grouped metadata, optional
/// availability hint) followed by a compact, end-aligned action pair. The whole
/// surface opens the profile; the inner buttons own their own actions and win
/// hit-testing, so no tap double-navigates.
class QuranSessionTeacherCompactCard extends StatelessWidget {
  const QuranSessionTeacherCompactCard({
    super.key,
    required this.teacher,
    required this.onTap,
    this.availabilitySummary,
    this.onBook,
    this.onViewProfile,
  });

  final QuranTeacher teacher;
  final VoidCallback onTap;
  final TeacherAvailabilitySummary? availabilitySummary;
  final VoidCallback? onBook;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;

    return Padding(
      padding: feature.cardPaddingInsets(),
      child: QuranSessionsSurfaceCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TeacherInitialsAvatar(
                  displayName: teacher.displayName,
                  radius: feature.listAvatarRadius,
                  avatarUrl: teacher.avatarUrl,
                ),
                SizedBox(width: feature.cardGap),
                Expanded(
                  child: _TeacherIdentity(
                    teacher: teacher,
                    availabilitySummary: availabilitySummary,
                  ),
                ),
              ],
            ),
            SizedBox(height: feature.cardGap),
            _TeacherActions(
              onBook: onBook ?? onTap,
              onViewProfile: onViewProfile ?? onTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Name + grouped metadata (rating · specialization · price) + availability.
class _TeacherIdentity extends StatelessWidget {
  const _TeacherIdentity({
    required this.teacher,
    required this.availabilitySummary,
  });

  final QuranTeacher teacher;
  final TeacherAvailabilitySummary? availabilitySummary;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final l10n = context.quranSessionsL10n;
    final summary = availabilitySummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teacher.displayName,
          style: feature.cardTitleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: feature.listItemGap),
        Wrap(
          spacing: feature.listItemGap,
          runSpacing: feature.listItemGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _InlineRating(teacher: teacher),
            if (teacher.specializations.isNotEmpty)
              QuranSessionsMetadataChip(
                label: l10n.specializationLabel(teacher.specializations.first),
              ),
            QuranSessionPriceChip(teacher: teacher),
          ],
        ),
        if (summary != null) ...[
          SizedBox(height: feature.listItemGap),
          _AvailabilityHint(summary: summary),
        ],
      ],
    );
  }
}

class _InlineRating extends StatelessWidget {
  const _InlineRating({required this.teacher});

  final QuranTeacher teacher;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final isNew = teacher.totalReviews == 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: tokens.iconSizeSmall,
          color: feature.ratingColor,
        ),
        SizedBox(width: tokens.spaceTiny),
        Text(
          isNew
              ? l10n.teacherNewRating
              : '${teacher.averageRating.toStringAsFixed(1)}'
                    ' (${teacher.totalReviews})',
          style: feature.priceBadgeStyle.copyWith(color: feature.ratingColor),
        ),
      ],
    );
  }
}

class _AvailabilityHint extends StatelessWidget {
  const _AvailabilityHint({required this.summary});

  final TeacherAvailabilitySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final color = summary.hasAvailableSlots
        ? feature.success
        : feature.helperTextColor;

    return Row(
      children: [
        Icon(Icons.schedule_outlined, size: tokens.iconSizeSmall, color: color),
        SizedBox(width: tokens.spaceTiny),
        Flexible(
          child: Text(
            summary.availabilityLabel(
              l10n,
              localeName: Localizations.localeOf(context).toString(),
            ),
            style: feature.cardMetaStyle.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Compact, end-aligned action pair: secondary "View profile" + primary "Book".
class _TeacherActions extends StatelessWidget {
  const _TeacherActions({required this.onBook, required this.onViewProfile});

  final VoidCallback onBook;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final feature = context.quranSessionsTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TilawaButton(
          text: l10n.teacherBookAction,
          size: TilawaButtonSize.small,
          onPressed: onBook,
        ),
        SizedBox(width: feature.listItemGap),
        TilawaButton(
          text: l10n.viewTeacherProfile,
          variant: TilawaButtonVariant.ghost,
          size: TilawaButtonSize.small,
          onPressed: onViewProfile,
        ),
      ],
    );
  }
}
