import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import '../l10n/dedication_relation_l10n.dart';
import 'sadaqah_jariyah_letter_avatar.dart';

/// Shared dedication row used for founding and all other published entries.
class SadaqahJariyahDedicationCard extends StatelessWidget {
  const SadaqahJariyahDedicationCard({
    required this.dedication,
    this.photoUrl,
    super.key,
  });

  final Dedication dedication;
  final String? photoUrl;

  static const String foundingAsset = 'assets/images/ahmed.png';
  static const double _avatarSize = 56;

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
    final String? note = _resolvedNote(context);

    return Semantics(
      label: dedication.displayName,
      child: DecoratedBox(
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
                    if (note != null) ...[
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
      ),
    );
  }

  String? _resolvedNote(BuildContext context) {
    final String? note = dedication.note?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }
    if (dedication.isFounding) {
      return context.l10n.sadaqahJariyahFoundingOrigin;
    }
    return null;
  }

  Widget _avatar(BuildContext context) {
    final String? url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(context),
        ),
      );
    }
    return _fallbackAvatar(context);
  }

  Widget _fallbackAvatar(BuildContext context) {
    if (dedication.isFounding) {
      return ClipOval(
        child: Image.asset(
          foundingAsset,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => SadaqahJariyahLetterAvatar(
            name: dedication.displayName,
            size: _avatarSize,
          ),
        ),
      );
    }
    return SadaqahJariyahLetterAvatar(
      name: dedication.displayName,
      size: _avatarSize,
    );
  }
}
