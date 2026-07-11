import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_pricing_quote.dart';
import '../models/teacher_availability_summary.dart';
import '../theme/quran_sessions_status_colors.dart';
import 'quran_session_price_chip.dart';
import 'teacher_discovery_details.dart';
import 'teacher_initials_avatar.dart';

/// Tappable teacher discovery row — whole card opens the teacher profile.
///
/// No inline actions: booking and profile details live on the profile screen.
class QuranSessionTeacherCompactCard extends StatelessWidget {
  const QuranSessionTeacherCompactCard({
    super.key,
    required this.teacher,
    required this.onTap,
    this.availabilitySummary,
    this.pricing,
  });

  final QuranTeacher teacher;
  final VoidCallback onTap;
  final TeacherAvailabilitySummary? availabilitySummary;

  /// Market-resolved pricing for the viewer; null hides the price badge.
  final SessionPricingQuote? pricing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceExtraSmall,
      ),
      child: TilawaCard(
        onTap: onTap,
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TeacherInitialsAvatar(
              displayName: teacher.displayName,
              radius: tokens.iconSizeSmall + 2,
              avatarUrl: teacher.avatarUrl,
            ),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: _TeacherIdentityBlock(
                teacher: teacher,
                availabilitySummary: availabilitySummary,
                pricing: pricing,
              ),
            ),
            SizedBox(width: tokens.spaceTiny),
            Icon(
              Icons.chevron_right_rounded,
              size: tokens.iconSizeSmall,
              color: scheme.onSurfaceVariant,
              textDirection: Directionality.of(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherIdentityBlock extends StatelessWidget {
  const _TeacherIdentityBlock({
    required this.teacher,
    required this.availabilitySummary,
    this.pricing,
  });

  final QuranTeacher teacher;
  final TeacherAvailabilitySummary? availabilitySummary;
  final SessionPricingQuote? pricing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.quranSessionsL10n;
    final tokens = theme.tokens;
    final summary = availabilitySummary;
    final denseGap = tokens.spaceTiny;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          teacher.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
        if (teacher.isVerified) ...[
          SizedBox(height: tokens.spaceTiny),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TilawaVerifiedTeacherBadge(
              label: l10n.verifiedTeacherBadge,
            ),
          ),
        ],
        SizedBox(height: tokens.spaceExtraSmall),
        Wrap(
          spacing: tokens.spaceExtraSmall,
          runSpacing: denseGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _InlineRating(teacher: teacher),
            if (teacher.specializations.isNotEmpty)
              TilawaMetadataChip(
                label: l10n.specializationLabel(teacher.specializations.first),
              ),
            QuranSessionPriceChip(teacher: teacher, pricing: pricing),
          ],
        ),
        SizedBox(height: denseGap),
        TeacherDiscoveryDetails(teacher: teacher, dense: true),
        if (teacher.bio.isNotEmpty) ...[
          SizedBox(height: denseGap),
          Text(
            teacher.bio,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (summary != null) ...[
          SizedBox(height: denseGap),
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
    final theme = Theme.of(context);
    final status = context.quranSessionsStatus;
    final tokens = theme.tokens;
    final isNew = teacher.totalReviews == 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: tokens.iconSizeSmall,
          color: status.rating,
        ),
        SizedBox(width: tokens.spaceTiny),
        Text(
          isNew
              ? l10n.teacherNewRating
              : '${teacher.averageRating.toStringAsFixed(1)}'
                    ' (${teacher.totalReviews})',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: status.rating,
          ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final color = summary.hasAvailableSlots
        ? scheme.tertiary
        : scheme.onSurfaceVariant;

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
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }
}
