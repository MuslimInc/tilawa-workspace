import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../theme/quran_sessions_theme.dart';
import 'quran_sessions_surface_card.dart';

/// Loading placeholder matching [QuranSessionTeacherCompactCard] layout.
class TeacherCardCompactSkeleton extends StatelessWidget {
  const TeacherCardCompactSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final feature = context.quranSessionsTheme;

    return Padding(
      padding: feature.cardPaddingInsets(),
      child: QuranSessionsSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(
                  width: feature.listAvatarRadius * 2,
                  height: feature.listAvatarRadius * 2,
                  radius: feature.listAvatarRadius,
                  color: scheme.surfaceContainerHighest,
                ),
                SizedBox(width: feature.cardGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(
                        width: double.infinity,
                        height: tokens.spaceMedium,
                        color: scheme.surfaceContainerHighest,
                      ),
                      SizedBox(height: feature.listItemGap),
                      _Bone(
                        width: tokens.spaceXXL * 2,
                        height: tokens.spaceSmall,
                        color: scheme.surfaceContainerHigh,
                      ),
                      SizedBox(height: feature.listItemGap),
                      _Bone(
                        width: tokens.spaceXXL,
                        height: tokens.spaceSmall,
                        color: scheme.surfaceContainerHigh,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: feature.sectionGap),
            _Bone(
              width: double.infinity,
              height: tokens.spaceLarge,
              color: scheme.surfaceContainerHigh,
            ),
            SizedBox(height: feature.listItemGap),
            _Bone(
              width: tokens.spaceXXL * 2,
              height: tokens.spaceMedium,
              color: scheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    required this.color,
    this.radius,
  });

  final double width;
  final double height;
  final Color color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          radius ?? feature.dateChipRadius,
        ),
      ),
    );
  }
}
