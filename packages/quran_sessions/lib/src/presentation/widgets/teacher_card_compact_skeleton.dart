import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Loading placeholder matching [QuranSessionTeacherCompactCard] layout.
class TeacherCardCompactSkeleton extends StatelessWidget {
  const TeacherCardCompactSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final avatarRadius = tokens.iconSizeSmall + 2;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceExtraSmall,
      ),
      child: TilawaCard(
        padding: EdgeInsets.all(tokens.spaceSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  radius: avatarRadius,
                  color: scheme.surfaceContainerHighest,
                ),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(
                        width: double.infinity,
                        height: tokens.spaceMedium,
                        color: scheme.surfaceContainerHighest,
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      _Bone(
                        width: tokens.spaceXXL * 2,
                        height: tokens.spaceSmall,
                        color: scheme.surfaceContainerHigh,
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
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
            SizedBox(height: tokens.spaceSmall),
            _Bone(
              width: double.infinity,
              height: tokens.spaceLarge,
              color: scheme.surfaceContainerHigh,
            ),
            SizedBox(height: tokens.spaceExtraSmall),
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
    final tokens = Theme.of(context).tokens;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          radius ?? tokens.resolveRadius(family: TilawaRadiusFamily.chip),
        ),
      ),
    );
  }
}
