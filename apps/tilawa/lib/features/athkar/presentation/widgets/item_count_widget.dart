import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';

/// Athkar counter scale relative to [TilawaCountProgressRingTokens.defaults].
const double kAthkarCountRingScale = 1;

/// Layout footprint for the counter in the Athkar footer row.
double athkarCountRingLayoutSize(BuildContext context) {
  final double outerSize = Theme.of(
    context,
  ).componentTokens.countProgressRing.outerSize;
  return outerSize * kAthkarCountRingScale;
}

class ItemCountWidget extends StatelessWidget {
  const ItemCountWidget({
    super.key,
    required this.item,
    required this.currentCount,
    required this.isDone,
    this.showProgressLabel = true,
  });

  final AthkarItem item;
  final int currentCount;
  final bool isDone;
  final bool showProgressLabel;

  @override
  Widget build(BuildContext context) {
    final double outerSize = Theme.of(
      context,
    ).componentTokens.countProgressRing.outerSize;
    final double layoutSize = outerSize * kAthkarCountRingScale;

    return SizedBox(
      width: layoutSize,
      height: layoutSize,
      child: FittedBox(
        child: SizedBox(
          width: outerSize,
          height: outerSize,
          child: TilawaCountProgressRing(
            currentCount: currentCount,
            totalCount: item.count,
            isDone: isDone,
            showProgressLabel: showProgressLabel,
          ),
        ),
      ),
    );
  }
}
