import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/domain/pinned_athkar_display_order.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_section_link.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_ritual_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_pinned_athkar_group.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_category.dart';
import '../athkar_category_presentation.dart';
import '../cubit/pinned_athkar_cubit.dart';
import '../cubit/pinned_athkar_state.dart';

class PinnedAthkarHomeSection extends StatelessWidget {
  const PinnedAthkarHomeSection({
    super.key,
    this.hideContextualFeatured = false,
  });

  /// When true, the contextual featured card is omitted (shown in
  /// [HomeTodayFeaturedCarousel] instead).
  final bool hideContextualFeatured;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinnedAthkarCubit, PinnedAthkarState>(
      builder: (context, state) {
        if (state.status == PinnedAthkarStatus.initial ||
            state.status == PinnedAthkarStatus.loading) {
          return const HomeDashboardCard(
            surface: TilawaCardSurface.raised,
            child: TilawaLoadingIndicator(),
          );
        }
        if (state.status == PinnedAthkarStatus.failure && !state.hasLoaded) {
          return _PinnedAthkarFailureCard(
            onRetry: () => context.read<PinnedAthkarCubit>().load(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PinnedAthkarSectionHeader(
              onEdit: () => _showPinnedAthkarPicker(context),
            ),
            SizedBox(height: context.tokens.spaceMedium),
            if (state.pinnedCategories.isEmpty)
              _PinnedAthkarEmptyCard(
                onChoose: () => _showPinnedAthkarPicker(context),
              )
            else
              _PinnedAthkarQuickAccess(
                categories: state.pinnedCategories,
                onEdit: () => _showPinnedAthkarPicker(context),
                hideContextualFeatured: hideContextualFeatured,
              ),
          ],
        );
      },
    );
  }

  Future<void> _showPinnedAthkarPicker(BuildContext context) {
    final cubit = context.read<PinnedAthkarCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    return showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      sheetSemanticsLabel: context.l10n.homePinnedAthkarPickerTitle,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: const _PinnedAthkarPickerSheet(),
        );
      },
    );
  }
}

class _PinnedAthkarSectionHeader extends StatelessWidget {
  const _PinnedAthkarSectionHeader({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TilawaSectionTitle(title: context.l10n.homeAthkarRitualsTitle),
        ),
        HomeSeeAllLink(
          onPressed: () => const AthkarCategoriesRoute().push(context),
        ),
        TilawaIconActionButton(
          icon: Icons.edit_outlined,
          onTap: onEdit,
          backgroundColor: Colors.transparent,
          tooltip: context.l10n.homePinnedAthkarEdit,
          semanticLabel: context.l10n.homePinnedAthkarEdit,
        ),
      ],
    );
  }
}

class _PinnedAthkarQuickAccess extends StatelessWidget {
  const _PinnedAthkarQuickAccess({
    required this.categories,
    required this.onEdit,
    this.hideContextualFeatured = false,
  });

  final List<AthkarCategory> categories;
  final VoidCallback onEdit;
  final bool hideContextualFeatured;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<AthkarCategory> ordered = orderPinnedAthkarForTime(
      pinned: categories,
      now: now,
    );
    final AthkarCategory? featured = contextualAthkarCategory(
      categories: ordered,
      now: now,
    );
    final List<AthkarCategory> stripCategories = featured == null
        ? categories
        : categories.where((c) => c.id != featured.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (featured != null && !hideContextualFeatured) ...[
          HomeFeaturedRitualCard(
            category: featured,
            promptLabel: (title) =>
                context.l10n.homeContextualAthkarPrompt(title),
            nowBadgeLabel: context.l10n.homeAthkarNowBadge,
            startLabel: context.l10n.homeFeaturedRitualStart,
          ),
          SizedBox(height: context.tokens.spaceSmall),
        ],
        if (stripCategories.isNotEmpty)
          HomePinnedAthkarGroup(
            categories: stripCategories,
            onLongPressCategory: (_) => onEdit(),
          ),
      ],
    );
  }
}

class _PinnedAthkarEmptyCard extends StatelessWidget {
  const _PinnedAthkarEmptyCard({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      child: Column(
        spacing: tokens.spaceSmall,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homePinnedAthkarEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            context.l10n.homePinnedAthkarEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TilawaButton(
              text: context.l10n.homePinnedAthkarChoose,
              leadingIcon: const Icon(Icons.add_rounded),
              variant: TilawaButtonVariant.secondary,
              onPressed: onChoose,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedAthkarFailureCard extends StatelessWidget {
  const _PinnedAthkarFailureCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      child: TilawaButton(
        text: context.l10n.retry,
        leadingIcon: const Icon(Icons.refresh_rounded),
        variant: TilawaButtonVariant.secondary,
        onPressed: onRetry,
      ),
    );
  }
}

class _PinnedAthkarPickerSheet extends StatelessWidget {
  const _PinnedAthkarPickerSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinnedAthkarCubit, PinnedAthkarState>(
      builder: (context, state) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: TilawaBottomSheetScaffold(
            topBar: TilawaBottomSheetTitleRow(
              title: context.l10n.homePinnedAthkarPickerTitle,
              trailingClose: true,
              closeSemanticLabel: context.l10n.close,
            ),
            children: [
              Flexible(
                child: ListView(
                  padding: TilawaBottomSheetScaffold.resolvedBodyPadding(
                    context,
                  ),
                  children: [
                    _PinnedAthkarPickerSummary(state: state),
                    SizedBox(height: context.tokens.spaceMedium),
                    _PinnedAthkarPickerList(
                      categories: _orderedPickerCategories(state),
                      state: state,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<AthkarCategory> _orderedPickerCategories(PinnedAthkarState state) {
    final pinnedIds = state.pinnedCategoryIds.toSet();
    final categoryById = {
      for (final category in state.categories) category.id: category,
    };
    return [
      for (final int id in state.pinnedCategoryIds)
        if (categoryById[id] != null) categoryById[id]!,
      for (final category in state.categories)
        if (!pinnedIds.contains(category.id)) category,
    ];
  }
}

class _PinnedAthkarPickerList extends StatelessWidget {
  const _PinnedAthkarPickerList({
    required this.categories,
    required this.state,
  });

  final List<AthkarCategory> categories;
  final PinnedAthkarState state;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return TilawaCard(
      surface: TilawaCardSurface.flat,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            if (i > 0)
              TilawaDivider(
                height: tokens.borderWidthThin,
                color: colorScheme.outlineVariant,
              ),
            _PinnedAthkarPickerRow(
              category: categories[i],
              state: state,
            ),
          ],
        ],
      ),
    );
  }
}

class _PinnedAthkarPickerSummary extends StatelessWidget {
  const _PinnedAthkarPickerSummary({required this.state});

  final PinnedAthkarState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    return Text(
      context.l10n.homePinnedAthkarPickerLimit(
        state.pinnedCategoryIds.length,
        PinnedAthkarState.maxPinnedCategories,
      ),
      style: textStyle,
    );
  }
}

class _PinnedAthkarPickerRow extends StatelessWidget {
  const _PinnedAthkarPickerRow({
    required this.category,
    required this.state,
  });

  final AthkarCategory category;
  final PinnedAthkarState state;

  @override
  Widget build(BuildContext context) {
    final title = localizedAthkarCategoryTitle(context, category);
    final selectedIndex = state.pinnedCategoryIds.indexOf(category.id);
    final bool selected = selectedIndex >= 0;
    final bool enabled = selected || state.canPinMore;

    return Row(
      children: [
        TilawaCheckbox(
          value: selected,
          onChanged: enabled ? (_) => _toggle(context) : null,
        ),
        Expanded(
          child: _PinnedAthkarPickerLabel(
            title: title,
            icon: athkarCategoryIcon(category.icon),
            selected: selected,
            enabled: enabled,
            onTap: () => _toggle(context),
          ),
        ),
        if (selected)
          _PinnedAthkarPickerReorderControls(
            title: title,
            selectedIndex: selectedIndex,
            pinnedCount: state.pinnedCategoryIds.length,
            onMove: (newIndex) => _move(context, selectedIndex, newIndex),
          ),
      ],
    );
  }

  void _toggle(BuildContext context) {
    context.read<PinnedAthkarCubit>().toggleCategory(category.id);
  }

  void _move(BuildContext context, int oldIndex, int newIndex) {
    context.read<PinnedAthkarCubit>().movePinnedCategory(
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }
}

class _PinnedAthkarPickerLabel extends StatelessWidget {
  const _PinnedAthkarPickerLabel({
    required this.title,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceMedium),
        child: Row(
          spacing: tokens.spaceSmall,
          children: [
            Icon(
              icon,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: enabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedAthkarPickerReorderControls extends StatelessWidget {
  const _PinnedAthkarPickerReorderControls({
    required this.title,
    required this.selectedIndex,
    required this.pinnedCount,
    required this.onMove,
  });

  final String title;
  final int selectedIndex;
  final int pinnedCount;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.l10n.homePinnedAthkarMoveUp(title),
          onPressed: selectedIndex > 0 ? () => onMove(selectedIndex - 1) : null,
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
        IconButton(
          tooltip: context.l10n.homePinnedAthkarMoveDown(title),
          onPressed: selectedIndex < pinnedCount - 1
              ? () => onMove(selectedIndex + 1)
              : null,
          icon: const Icon(Icons.arrow_downward_rounded),
        ),
      ],
    );
  }
}
