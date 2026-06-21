import 'package:flutter/material.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../../utils/price_formatter.dart';
import '../../utils/specialization_labels.dart';
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeacherInitialsAvatar(
                displayName: teacher.displayName,
                radius: 28,
                avatarUrl: teacher.avatarUrl,
              ),
              const SizedBox(width: 12),
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
                        _PriceChip(teacher: teacher, scheme: scheme),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: scheme.tertiary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          teacher.averageRating.toStringAsFixed(1),
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${teacher.totalReviews})',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _SpecializationChips(specs: teacher.specializations),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Price chip ────────────────────────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.teacher, required this.scheme});

  final QuranTeacher teacher;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final priceLabel = PriceFormatter.formatOrFree(
      pricingType: teacher.pricingType,
      price: teacher.price,
    );
    if (priceLabel.isEmpty) return const SizedBox.shrink();

    final isFree = teacher.pricingType == SessionPricingType.free;
    final label = priceLabel;
    final bg = isFree ? scheme.secondaryContainer : scheme.primaryContainer;
    final fg = isFree ? scheme.onSecondaryContainer : scheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Specialization chips ──────────────────────────────────────────────────────

class _SpecializationChips extends StatelessWidget {
  const _SpecializationChips({required this.specs});

  final List<String> specs;

  @override
  Widget build(BuildContext context) {
    final visible = specs.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: visible.map((code) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            SpecializationLabels.arabic(code),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
