import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../utils/teacher_location_label.dart';

/// Compact metadata under a teacher name — location, languages, sessions.
class TeacherDiscoveryDetails extends StatelessWidget {
  const TeacherDiscoveryDetails({
    super.key,
    required this.teacher,
    this.dense = false,
  });

  final QuranTeacher teacher;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.quranSessionsL10n;
    final tokens = theme.tokens;
    final gap = dense ? tokens.spaceTiny : tokens.spaceExtraSmall;
    final location = teacherLocationLabel(teacher);
    final languageLabels = teacher.languages
        .map(l10n.teachingLanguageLabel)
        .toList(growable: false);

    final lines = <Widget>[];
    if (location != null) {
      lines.add(
        _DetailLine(
          icon: Icons.location_on_outlined,
          label: location,
          dense: dense,
        ),
      );
    }
    if (languageLabels.isNotEmpty) {
      lines.add(
        _DetailLine(
          icon: Icons.translate_rounded,
          label: languageLabels.join(' · '),
          dense: dense,
        ),
      );
    }
    if (teacher.totalSessionsCompleted > 0) {
      lines.add(
        _DetailLine(
          icon: Icons.event_available_outlined,
          label: l10n.teacherSessionsCompleted(teacher.totalSessionsCompleted),
          dense: dense,
        ),
      );
    }

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          lines[i],
        ],
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.dense,
  });

  final IconData icon;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final style = dense
        ? theme.textTheme.bodySmall
        : theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: tokens.iconSizeSmall,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: tokens.spaceExtraSmall),
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: dense ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
