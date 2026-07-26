import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import 'sadaqah_jariyah_letter_avatar.dart';

class SadaqahJariyahFoundingCard extends StatelessWidget {
  const SadaqahJariyahFoundingCard({
    required this.dedication,
    this.photoUrl,
    super.key,
  });

  final Dedication dedication;
  final String? photoUrl;

  static const String foundingAsset = 'assets/images/ahmed.png';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final l10n = context.l10n;
    final String? note = dedication.note?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        border: Border.all(
          color: scheme.outlineVariant,
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipOval(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: _portrait(context),
                ),
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            Text(
              dedication.displayName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.spaceExtraSmall),
            Text(
              l10n.sadaqahJariyahRahimahullah,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceSmall),
            Text(
              (note != null && note.isNotEmpty)
                  ? note
                  : l10n.sadaqahJariyahFoundingOrigin,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: tokens.textHeightLoose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _portrait(BuildContext context) {
    final String? url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(foundingAsset, fit: BoxFit.cover),
      );
    }
    return Image.asset(
      foundingAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          SadaqahJariyahLetterAvatar(name: dedication.displayName, size: 96),
    );
  }
}
