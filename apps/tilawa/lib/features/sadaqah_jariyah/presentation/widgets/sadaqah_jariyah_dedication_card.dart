import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import '../l10n/dedication_relation_l10n.dart';
import 'sadaqah_jariyah_letter_avatar.dart';

/// Shared dedication row. Founding uses a slightly larger avatar + status chip.
class SadaqahJariyahDedicationCard extends StatelessWidget {
  const SadaqahJariyahDedicationCard({
    required this.dedication,
    this.photoUrl,
    super.key,
  });

  final Dedication dedication;
  final String? photoUrl;

  static const String foundingAsset = 'assets/images/ahmed.png';
  static const double _avatarSize = 40;
  static const double _foundingAvatarSize = 44;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final l10n = context.l10n;
    final bool isFounding = dedication.isFounding;
    final double avatarSize = isFounding ? _foundingAvatarSize : _avatarSize;
    final String? relation = localizedDedicationRelation(
      context,
      dedication.relation,
      relationOther: dedication.relationOther,
    );
    final String? note = dedication.note?.trim();
    final String? resolvedNote = (note != null && note.isNotEmpty)
        ? note
        : null;

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
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(context, size: avatarSize),
              SizedBox(width: tokens.spaceSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dedication.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isFounding) ...[
                      SizedBox(height: tokens.spaceExtraSmall),
                      TilawaStatusChip(
                        label: l10n.sadaqahJariyahFoundingLabel,
                        backgroundColor: scheme.secondaryContainer,
                        foregroundColor: scheme.onSecondaryContainer,
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceSmall,
                          vertical: tokens.spaceExtraSmall / 2,
                        ),
                      ),
                    ],
                    if (relation != null) ...[
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        relation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (resolvedNote != null) ...[
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        resolvedNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
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

  Widget _avatar(BuildContext context, {required double size}) {
    final String? url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(context, size: size),
        ),
      );
    }
    return _fallbackAvatar(context, size: size);
  }

  Widget _fallbackAvatar(BuildContext context, {required double size}) {
    if (dedication.isFounding) {
      return ClipOval(
        child: Image.asset(
          foundingAsset,
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
    return SadaqahJariyahLetterAvatar(
      name: dedication.displayName,
      size: size,
    );
  }
}
