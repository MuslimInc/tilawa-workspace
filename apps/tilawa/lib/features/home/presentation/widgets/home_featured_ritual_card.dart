import 'package:flutter/material.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/features/home/presentation/widgets/home_travel_destination_card.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Layout for [HomeFeaturedRitualCard].
enum HomeFeaturedRitualCardLayout {
  /// Inline row for pinned-athkar sections.
  row,

  /// Travel carousel destination card with warm header band.
  carousel,
}

/// Primary one-tap ritual card for the time-relevant pinned athkar.
class HomeFeaturedRitualCard extends StatelessWidget {
  const HomeFeaturedRitualCard({
    super.key,
    required this.category,
    required this.promptLabel,
    required this.nowBadgeLabel,
    required this.startLabel,
    this.layout = HomeFeaturedRitualCardLayout.row,
    this.carouselTintIndex = 1,
  });

  final AthkarCategory category;
  final String Function(String categoryTitle) promptLabel;
  final String nowBadgeLabel;
  final String startLabel;
  final HomeFeaturedRitualCardLayout layout;
  final int carouselTintIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final String title = localizedAthkarCategoryTitle(context, category);
    final String prompt = promptLabel(title);

    void openDetails() {
      AthkarDetailsRoute(
        categoryId: category.id,
        categoryName: title,
        source: 'home_featured_ritual',
      ).push(context);
    }

    if (layout == HomeFeaturedRitualCardLayout.carousel) {
      return HomeTravelDestinationCard(
        tintIndex: carouselTintIndex,
        icon: athkarCategoryIcon(category.icon),
        title: prompt,
        subtitle: startLabel,
        onTap: openDetails,
        semanticLabel: prompt,
        trailing: _PulseAnimator(
          child: TilawaStatusChip(
            label: nowBadgeLabel,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
      );
    }

    final cardTokens = theme.componentTokens.homeDashboardCard;
    final Color warmStart = cardTokens.gradientStart.withValues(alpha: 0.28);
    final Color warmEnd = cardTokens.gradientEnd.withValues(alpha: 0.18);
    final Color tintFg = colorScheme.onSurface;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.card);

    return Semantics(
      button: true,
      label: prompt,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: openDetails,
          borderRadius: BorderRadius.circular(radius),
          splashColor: cardTokens.gradientEnd.withValues(alpha: 0.12),
          highlightColor: cardTokens.gradientEnd.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [warmStart, warmEnd],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: cardTokens.gradientEnd.withValues(alpha: 0.25),
                width: tokens.borderWidthThin * 2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceSmall),
              child: Row(
                spacing: tokens.spaceSmall,
                children: [
                  Container(
                    width: tokens.spaceExtraLarge + tokens.spaceSmall,
                    height: tokens.spaceExtraLarge + tokens.spaceSmall,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(
                        tokens.resolveRadius(
                          family: TilawaRadiusFamily.decorative,
                        ),
                      ),
                    ),
                    child: Icon(
                      athkarCategoryIcon(category.icon),
                      color: colorScheme.onPrimary,
                      size: tokens.iconSizeMedium,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: tokens.spaceExtraSmall,
                      children: [
                        _PulseAnimator(
                          child: TilawaStatusChip(
                            label: nowBadgeLabel,
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                        Text(
                          prompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: tintFg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          startLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tintFg.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Keep the right chevron in both LTR and RTL; this icon
                  // reads correctly in Arabic and avoids unwanted mirroring.
                  Icon(
                    Icons.chevron_right_rounded,
                    size: tokens.iconSizeSmall,
                    color: tintFg.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseAnimator extends StatefulWidget {
  const _PulseAnimator({required this.child});

  final Widget child;

  @override
  State<_PulseAnimator> createState() => _PulseAnimatorState();
}

class _PulseAnimatorState extends State<_PulseAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
