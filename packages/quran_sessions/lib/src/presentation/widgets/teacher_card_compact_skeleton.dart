import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Loading placeholder matching [QuranSessionTeacherCompactCard] layout.
///
/// Renders bones under the nearest ancestor [TilawaSkeleton] scope so the
/// shimmer sweep and base/highlight colours match every other skeleton in the
/// app (e.g. the home dashboard). Wrap the group of skeletons in a single
/// [TilawaSkeleton] at the call site — see [QuranSessionsHomeScreen] and
/// [TeacherListScreen] — so one sweep and one loading announcement cover the
/// whole placeholder region.
class TeacherCardCompactSkeleton extends StatelessWidget {
  const TeacherCardCompactSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double avatarDimension =
        (tokens.iconSizeSmall + tokens.spaceTiny) * 2;

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
                TilawaSkeletonBone.circle(dimension: avatarDimension),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TilawaSkeletonLine(style: theme.textTheme.titleSmall),
                      SizedBox(height: tokens.spaceExtraSmall),
                      TilawaSkeletonLine(
                        width: tokens.spaceXXL * 2,
                        style: theme.textTheme.bodySmall,
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      TilawaSkeletonLine(
                        width: tokens.spaceXXL,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSmall),
            TilawaSkeletonLine(style: theme.textTheme.titleMedium),
            SizedBox(height: tokens.spaceExtraSmall),
            TilawaSkeletonLine(
              width: tokens.spaceXXL * 2,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
