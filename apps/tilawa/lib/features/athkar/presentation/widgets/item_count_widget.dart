import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';

class ItemCountWidget extends StatelessWidget {
  const ItemCountWidget({
    super.key,
    required this.item,
    required this.currentCount,
    required this.isDone,
  });

  final AthkarItem item;
  final int currentCount;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return TilawaCountProgressRing(
      currentCount: currentCount,
      totalCount: item.count,
      isDone: isDone,
    );
  }
}
