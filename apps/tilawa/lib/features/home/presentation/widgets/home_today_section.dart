import 'package:flutter/material.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Zone 2 — Today: optional Today Plan only (prayer strip removed — hero owns
/// the prayer context).
class HomeTodaySection extends StatelessWidget {
  const HomeTodaySection({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (!isTodayPlanEnabled()) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TodayPlanCard(),
        SizedBox(height: tokens.spaceExtraLarge),
      ],
    );
  }
}
