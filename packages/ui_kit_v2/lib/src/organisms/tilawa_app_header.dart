import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../foundation/foundation.dart';

/// Home-screen header. Greeting → name → soft subtitle → optional search.
/// Mirrors `.tw-app-header`.
class TilawaAppHeader extends StatelessWidget {
  const TilawaAppHeader({
    required this.greeting,
    required this.name,
    this.subtitle,
    this.search,
    this.profileInitials,
    this.onProfilePressed,
    super.key,
  });

  final String greeting;
  final String name;
  final String? subtitle;
  final Widget? search;
  final String? profileInitials;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(gradient: TilawaPalette.softSurface),
          padding: const EdgeInsets.fromLTRB(
            TilawaSpacing.padX,
            TilawaSpacing.s16,
            TilawaSpacing.padX,
            TilawaSpacing.s2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.typography.captionMobile,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: theme.typography.heroMobile.copyWith(color: c.fg1),
              ),
              if ((subtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.typography.captionMobile.copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
              if (search != null) ...[
                const SizedBox(height: 16),
                search!,
              ],
            ],
          ),
        ),
        if (profileInitials != null)
          Positioned(
            top: TilawaSpacing.s10 + 12,
            right: TilawaSpacing.padX,
            child: GestureDetector(
              onTap: onProfilePressed,
              child: TilawaAvatar(
                initials: profileInitials!,
              ),
            ),
          ),
      ],
    );
  }
}
