import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class RadioHomeSkeleton extends StatelessWidget {
  const RadioHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TilawaSkeleton(
      child: ListView(
        padding: EdgeInsets.all(tokens.spaceMedium),
        children: [
          TilawaSkeletonBone(
            width: double.infinity,
            height: 160,
            borderRadius: tokens.radiusLarge,
          ),
          SizedBox(height: tokens.spaceLarge),
          TilawaSkeletonBone(
            width: double.infinity,
            height: 48,
            borderRadius: tokens.radiusMedium,
          ),
          SizedBox(height: tokens.spaceLarge),
          TilawaSkeletonLine(style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: tokens.spaceSmall),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSmall),
              itemBuilder: (_, _) => TilawaSkeletonBone(
                width: 132,
                height: 120,
                borderRadius: tokens.radiusMedium,
              ),
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          for (int i = 0; i < 6; i++) ...[
            TilawaSkeletonBone(
              width: double.infinity,
              height: 72,
              borderRadius: tokens.radiusMedium,
            ),
            SizedBox(height: tokens.spaceSmall),
          ],
        ],
      ),
    );
  }
}
