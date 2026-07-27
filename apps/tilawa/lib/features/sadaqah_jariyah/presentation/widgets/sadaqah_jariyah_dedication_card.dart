import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import 'sadaqah_jariyah_letter_avatar.dart';

/// Compact dedication row: photo + name only.
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;

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
            children: [
              _avatar(context),
              SizedBox(width: tokens.spaceSmall),
              Expanded(
                child: Text(
                  dedication.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
