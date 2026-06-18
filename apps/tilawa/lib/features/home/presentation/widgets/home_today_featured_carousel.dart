import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/domain/pinned_athkar_display_order.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_ritual_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quran_resume_card.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Horizontal featured row (travel-app "popular destinations" pattern).
class HomeTodayFeaturedCarousel extends StatelessWidget {
  const HomeTodayFeaturedCarousel({super.key});

  static double cardWidth(BuildContext context) {
    final double viewport = MediaQuery.sizeOf(context).width;
    final double inset = context.tokens.spaceMedium * 2;
    return math.min(300, viewport - inset - context.tokens.spaceLarge);
  }

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = context.tokens;
    final double width = cardWidth(context);

    return Semantics(
      label: context.l10n.homeTodayTitle,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          spacing: tokens.spaceMedium,
          children: [
            _CarouselSlot(width: width, child: const HomeQuranResumeCard()),
            const _HomeTodayCarouselAthkarSlot(),
            if (isSmartKhatmaEnabled())
              _CarouselSlot(
                width: width,
                child: const SmartKhatmaHomeEntryCard(),
              ),
          ],
        ),
      ),
    );
  }
}

class _CarouselSlot extends StatelessWidget {
  const _CarouselSlot({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _HomeTodayCarouselAthkarSlot extends StatelessWidget {
  const _HomeTodayCarouselAthkarSlot();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinnedAthkarCubit, PinnedAthkarState>(
      buildWhen: (previous, current) =>
          previous.pinnedCategories != current.pinnedCategories ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.status != PinnedAthkarStatus.ready ||
            state.pinnedCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        final featured = contextualAthkarCategory(
          categories: orderPinnedAthkarForTime(
            pinned: state.pinnedCategories,
            now: DateTime.now(),
          ),
          now: DateTime.now(),
        );
        if (featured == null) {
          return const SizedBox.shrink();
        }

        return _CarouselSlot(
          width: HomeTodayFeaturedCarousel.cardWidth(context),
          child: HomeFeaturedRitualCard(
            category: featured,
            promptLabel: (title) =>
                context.l10n.homeContextualAthkarPrompt(title),
            nowBadgeLabel: context.l10n.homeAthkarNowBadge,
            startLabel: context.l10n.homeFeaturedRitualStart,
            layout: HomeFeaturedRitualCardLayout.carousel,
            carouselTintIndex: 1,
          ),
        );
      },
    );
  }
}
