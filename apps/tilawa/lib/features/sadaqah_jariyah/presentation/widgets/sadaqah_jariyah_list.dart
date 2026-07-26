import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import 'sadaqah_jariyah_dedication_card.dart';
import 'sadaqah_jariyah_founding_card.dart';

class SadaqahJariyahList extends StatelessWidget {
  const SadaqahJariyahList({
    required this.dedications,
    required this.photoUrls,
    super.key,
  });

  final List<Dedication> dedications;
  final Map<String, String?> photoUrls;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final l10n = context.l10n;

    final List<Dedication> founding = dedications
        .where((Dedication d) => d.isFounding)
        .toList();
    final List<Dedication> featured = dedications
        .where((Dedication d) => !d.isFounding && d.isFeatured)
        .toList();
    final List<Dedication> rest = dedications
        .where((Dedication d) => !d.isFounding && !d.isFeatured)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final Dedication d in founding) ...[
          SadaqahJariyahFoundingCard(
            dedication: d,
            photoUrl: photoUrls[d.id],
          ),
          SizedBox(height: tokens.spaceLarge),
        ],
        if (founding.isNotEmpty && featured.isEmpty && rest.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceMedium),
            child: Text(
              l10n.sadaqahJariyahEmptyOthers,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (featured.isNotEmpty) ...[
          Text(
            l10n.sadaqahJariyahFeaturedSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          for (final Dedication d in featured) ...[
            SadaqahJariyahDedicationCard(
              dedication: d,
              photoUrl: photoUrls[d.id],
            ),
            SizedBox(height: tokens.spaceMedium),
          ],
        ],
        for (final Dedication d in rest) ...[
          SadaqahJariyahDedicationCard(
            dedication: d,
            photoUrl: photoUrls[d.id],
          ),
          SizedBox(height: tokens.spaceMedium),
        ],
      ],
    );
  }
}
