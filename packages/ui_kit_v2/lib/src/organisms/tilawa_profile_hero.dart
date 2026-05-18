import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../foundation/foundation.dart';

/// Profile-screen hero. Gold-ringed 80px avatar → name → email → ghost
/// "Edit profile" CTA. Mirrors `.tw-profile-hero`.
class TilawaProfileHero extends StatelessWidget {
  const TilawaProfileHero({
    required this.initials,
    required this.name,
    required this.email,
    this.onEdit,
    super.key,
  });

  final String initials;
  final String name;
  final String email;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    return Container(
      decoration: const BoxDecoration(gradient: TilawaPalette.softSurface),
      padding: const EdgeInsets.fromLTRB(
        TilawaSpacing.padX,
        TilawaSpacing.s16 - 8,
        TilawaSpacing.padX,
        20,
      ),
      child: Column(
        children: [
          TilawaAvatar(initials: initials, size: TilawaAvatarSize.xl),
          const SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: c.fg1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: TextStyle(
              fontFamily: TilawaFontFamily.ui,
              fontSize: 13,
              color: c.fg2,
            ),
          ),
          const SizedBox(height: 12),
          TilawaBtn(
            label: 'Edit profile',
            onPressed: onEdit,
            variant: TilawaBtnVariant.ghost,
            size: TilawaBtnSize.sm,
          ),
        ],
      ),
    );
  }
}
