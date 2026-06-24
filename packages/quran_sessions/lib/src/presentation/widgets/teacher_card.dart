import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../../utils/price_formatter.dart';
import 'teacher_initials_avatar.dart';

/// Compact card showing teacher avatar, name, specializations, rating, and price.
/// Used in [TeacherListScreen] and the feature home preview.
class TeacherCard extends StatelessWidget {
  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
  });

  final QuranTeacher teacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = Theme.of(context).tokens;
    final avatarRadius = tokens.iconSizeLarge + tokens.spaceExtraSmall;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceExtraSmall + 2,
      ),
      child: TilawaCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TeacherInitialsAvatar(
              displayName: teacher.displayName,
              radius: avatarRadius,
              avatarUrl: teacher.avatarUrl,
            ),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          teacher.displayName,
                          style: textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _PriceChip(teacher: teacher),
                    ],
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: tokens.iconSizeExtraSmall + 2,
                        color: scheme.tertiary,
                      ),
                      SizedBox(width: tokens.spaceExtraSmall / 2),
                      Text(
                        teacher.averageRating.toStringAsFixed(1),
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: tokens.spaceExtraSmall),
                      Text(
                        '(${teacher.totalReviews})',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceSmall - 2),
                  _SpecializationChips(specs: teacher.specializations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.teacher});

  final QuranTeacher teacher;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final priceLabel = PriceFormatter.formatOrFree(
      l10n: context.quranSessionsL10n,
      pricingType: teacher.pricingType,
      price: teacher.price,
    );
    if (priceLabel.isEmpty) return const SizedBox.shrink();

    final isFree = teacher.pricingType == SessionPricingType.free;
    final bg = isFree ? scheme.secondaryContainer : scheme.primaryContainer;
    final fg = isFree ? scheme.onSecondaryContainer : scheme.onPrimaryContainer;

    return TilawaStatusChip(
      label: priceLabel,
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }
}

class _SpecializationChips extends StatelessWidget {
  const _SpecializationChips({required this.specs});

  final List<String> specs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final visible = specs.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: tokens.spaceExtraSmall,
      runSpacing: tokens.spaceExtraSmall,
      children: visible.map((code) {
        return TilawaMetadataChip(label: l10n.specializationLabel(code));
      }).toList(),
    );
  }
}
