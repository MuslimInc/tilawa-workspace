import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import '../l10n/dedication_relation_l10n.dart';
import 'sadaqah_jariyah_letter_avatar.dart';

class SadaqahJariyahDedicationCard extends StatelessWidget {
  const SadaqahJariyahDedicationCard({
    required this.dedication,
    this.photoUrl,
    super.key,
  });

  final Dedication dedication;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final l10n = context.l10n;
    final String? relation = localizedDedicationRelation(
      context,
      dedication.relation,
      relationOther: dedication.relationOther,
    );
    final String? note = dedication.note?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        border: Border.all(
          color: scheme.outlineVariant,
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(context),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dedication.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    l10n.sadaqahJariyahRahimahullah,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (relation != null) ...[
                    SizedBox(height: tokens.spaceExtraSmall),
                    Text(
                      relation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (note != null && note.isNotEmpty) ...[
                    SizedBox(height: tokens.spaceSmall),
                    Text(
                      note,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: tokens.textHeightLoose,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    const double size = 48;
    final String? url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => SadaqahJariyahLetterAvatar(
            name: dedication.displayName,
            size: size,
          ),
        ),
      );
    }
    return SadaqahJariyahLetterAvatar(name: dedication.displayName, size: size);
  }
}
