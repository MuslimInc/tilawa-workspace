import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/widgets/deferred_after_first_frame.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/home_primary_action_cubit.dart';
import '../cubit/home_primary_action_state.dart';
import 'home_athkar_compact_card.dart';
import 'home_dashboard_section.dart';
import 'home_discover_carousel.dart';
import 'home_features_hub.dart';
import 'home_listening_resume_row.dart';
import 'home_primary_action_zone.dart';

/// Home body — primary action, category grid, promos, and today content.
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomePrimaryActionZone(),
        DeferredAfterFirstFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: tokens.spaceMedium),
              HomeFeaturesHub(onOpenPrayer: onOpenPrayer),
              SizedBox(height: tokens.spaceExtraLarge),
              const HomeDiscoverCarousel(),
              SizedBox(height: tokens.spaceExtraLarge),
              if (isTodayPlanEnabled()) ...[
                const TodayPlanCard(),
                SizedBox(height: tokens.spaceLarge),
              ],
              HomeDashboardSection(
                title: context.l10n.homeTodayTitle,
                subtitle: context.l10n.homeTodaySubtitle,
                contentSpacing: tokens.spaceMedium,
                child: const HomeAthkarCompactCard(),
              ),
              SizedBox(height: tokens.spaceLarge),
              const _ConditionalListeningRow(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConditionalListeningRow extends StatelessWidget {
  const _ConditionalListeningRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePrimaryActionCubit, HomePrimaryActionState>(
      builder: (context, primaryState) {
        if (primaryState.kind == HomePrimaryActionKind.listening) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeListeningResumeRow(),
            SizedBox(height: context.tokens.spaceLarge),
          ],
        );
      },
    );
  }
}
