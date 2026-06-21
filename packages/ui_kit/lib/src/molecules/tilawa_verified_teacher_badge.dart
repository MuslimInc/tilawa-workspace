import 'package:flutter/material.dart';

import '../foundation/semantic_tints.dart';
import 'tilawa_status_chip.dart';

/// Positive verification badge for an approved, active Quran teacher.
///
/// Uses [TilawaSemanticTint.scholar] so it reads as credential, not warning.
class TilawaVerifiedTeacherBadge extends StatelessWidget {
  const TilawaVerifiedTeacherBadge({
    super.key,
    required this.label,
    this.icon = Icons.verified_rounded,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      child: TilawaStatusChip(
        label: label,
        icon: icon,
        backgroundColor: colorScheme.semanticTintBackground(
          TilawaSemanticTint.scholar,
        ),
        foregroundColor: colorScheme.semanticTintForeground(
          TilawaSemanticTint.scholar,
        ),
      ),
    );
  }
}
