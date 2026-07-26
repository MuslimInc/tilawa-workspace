import 'package:flutter/material.dart';
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

    if (dedications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < dedications.length; i++) ...[
          if (i > 0) SizedBox(height: tokens.spaceSmall),
          SadaqahJariyahDedicationCard(
            dedication: dedications[i],
            photoUrl: photoUrls[dedications[i].id],
          ),
        ],
      ],
    );
  }
}
