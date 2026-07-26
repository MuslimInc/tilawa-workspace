import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import 'sadaqah_jariyah_dedication_card.dart';

/// Vertical dedication list. Order is caller-owned (founding first).
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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (dedications.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool onlyFounding =
        dedications.length == 1 && dedications.first.isFounding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < dedications.length; i++) ...[
          if (i > 0) SizedBox(height: tokens.spaceMedium),
          SadaqahJariyahDedicationCard(
            dedication: dedications[i],
            photoUrl: photoUrls[dedications[i].id],
          ),
        ],
        if (onlyFounding) ...[
          SizedBox(height: tokens.spaceMedium),
          Text(
            l10n.sadaqahJariyahEmptyOthers,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: tokens.textHeightLoose,
            ),
          ),
        ],
      ],
    );
  }
}
