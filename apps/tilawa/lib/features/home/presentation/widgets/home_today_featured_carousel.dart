import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/pinned_athkar_display_order.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_ritual_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quran_resume_card.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Featured row for Quran resume, contextual athkar, and optional khatma.
///
/// Uses full-width cards on phones and a horizontal carousel on wider screens.
class HomeTodayFeaturedCarousel extends StatelessWidget {
  const HomeTodayFeaturedCarousel({super.key});

  static double carouselCardWidth(BuildContext context) {
    final double viewport = MediaQuery.sizeOf(context).width;
    final double inset = context.tokens.spaceMedium * 2;
    return math.min(300, viewport - inset - context.tokens.spaceLarge);
  }

  /// Fixed height for carousel peers — travel header band + two-line body.
  static double carouselSlotHeight(BuildContext context) {
    final TilawaDesignTokens tokens = context.tokens;
    return tokens.spaceMedium * 4 +
        tokens.iconSizeLarge +
        tokens.minInteractiveDimension +
        tokens.spaceLarge * 2;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinnedAthkarCubit, PinnedAthkarState>(
      buildWhen: (previous, current) =>
          previous.pinnedCategories != current.pinnedCategories ||
          previous.status != current.status,
      builder: (context, pinnedState) {
        final List<Widget> items = _FeaturedCarouselItems.build(
          context,
          pinnedState,
        );

        return Semantics(
          label: context.l10n.homeTodayTitle,
          child: _FeaturedCarouselLayout(items: items),
        );
      },
    );
  }
}

class _FeaturedCarouselLayout extends StatelessWidget {
  const _FeaturedCarouselLayout({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (items.length == 1) {
      return items.first;
    }

    final TilawaDesignTokens tokens = context.tokens;
    if (!context.isAtLeastMedium) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceSmall,
        children: items,
      );
    }

    return SizedBox(
      height: HomeTodayFeaturedCarousel.carouselSlotHeight(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceMedium,
          children: [
            for (final Widget item in items)
              SizedBox(
                width: HomeTodayFeaturedCarousel.carouselCardWidth(context),
                child: item,
              ),
          ],
        ),
      ),
    );
  }
}

abstract final class _FeaturedCarouselItems {
  const _FeaturedCarouselItems._();

  static List<Widget> build(
    BuildContext context,
    PinnedAthkarState pinnedState,
  ) {
    final List<Widget> items = <Widget>[
      const HomeQuranResumeCard(),
    ];

    final Widget? athkar = _contextualAthkarCard(context, pinnedState);
    if (athkar != null) {
      items.add(athkar);
    }

    if (isSmartKhatmaEnabled()) {
      items.add(const SmartKhatmaHomeEntryCard());
    }

    return items;
  }

  static Widget? _contextualAthkarCard(
    BuildContext context,
    PinnedAthkarState state,
  ) {
    if (state.status != PinnedAthkarStatus.ready ||
        state.pinnedCategories.isEmpty) {
      return null;
    }

    final AthkarCategory? featured = contextualAthkarCategory(
      categories: orderPinnedAthkarForTime(
        pinned: state.pinnedCategories,
        now: DateTime.now(),
      ),
      now: DateTime.now(),
    );
    if (featured == null) {
      return null;
    }

    return HomeFeaturedRitualCard(
      category: featured,
      promptLabel: (title) => context.l10n.homeContextualAthkarPrompt(title),
      nowBadgeLabel: context.l10n.homeAthkarNowBadge,
      startLabel: context.l10n.homeFeaturedRitualStart,
      layout: HomeFeaturedRitualCardLayout.carousel,
      carouselTintIndex: 1,
    );
  }
}
