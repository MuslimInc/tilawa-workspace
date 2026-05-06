import 'dart:async';
import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_card.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import '../bloc/reciters_bloc.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../reciter_semantics_ids.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 200);
  static const Duration _initialRecitersLoadDelay = Duration(
    milliseconds: 1500,
  );
  static const Duration _startupLiteUiDuration = Duration(milliseconds: 650);
  static const Duration _loadedResultsActivationDelay = Duration(
    milliseconds: 500,
  );

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _searchDebounceTimer;
  Timer? _initialLoadTimer;
  Timer? _loadedResultsActivationTimer;
  Timer? _startupLiteUiTimer;
  bool _isStartupLiteUi = true;
  bool _allowHeavyLoadedResults = false;
  late final FavoritesCubit _favoritesCubit;

  @override
  void initState() {
    super.initState();
    _favoritesCubit = getIt<FavoritesCubit>();
    _startupLiteUiTimer = Timer(_startupLiteUiDuration, () {
      if (!mounted) return;
      setState(() {
        _isStartupLiteUi = false;
      });
      _favoritesCubit.loadFavorites();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        '[PerfLogger][RecitersScreen] initial-load scheduled '
        'delayMs=${_initialRecitersLoadDelay.inMilliseconds}',
      );
      _initialLoadTimer = Timer(_initialRecitersLoadDelay, () {
        if (!mounted) return;
        debugPrint('[PerfLogger][RecitersScreen] initial-load started');
        context.read<RecitersBloc>().add(const LoadReciters());
      });
    });
  }

  void _scheduleLoadedResultsActivation() {
    _loadedResultsActivationTimer?.cancel();
    _loadedResultsActivationTimer = Timer(_loadedResultsActivationDelay, () {
      if (!mounted || _allowHeavyLoadedResults) return;
      setState(() {
        _allowHeavyLoadedResults = true;
      });
    });
  }

  @override
  void dispose() {
    _startupLiteUiTimer?.cancel();
    _loadedResultsActivationTimer?.cancel();
    _initialLoadTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _favoritesCubit.close();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _onLetterSelected(String? letter) {
    if (letter == null || letter.isEmpty) {
      _clearLetterFilter();
      return;
    }

    _focusNode.unfocus();
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    context.read<RecitersBloc>().add(FilterByLetter(letter));
    _scrollToTop();
  }

  void _clearLetterFilter() {
    context.read<RecitersBloc>().add(const ClearLetterFilter());
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());

    if (value.isEmpty) {
      context.read<RecitersBloc>().add(const ClearSearch());
      return;
    }

    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      if (!mounted) {
        return;
      }

      context.read<RecitersBloc>().add(SearchRecitersEvent(value));
      _scrollToTop();
    });
  }

  void _clearSearch() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    context.read<RecitersBloc>().add(const ClearSearch());
  }

  void _toggleFavoritesFilter(BuildContext context) {
    final favoritesState = context.read<FavoritesCubit>().state;
    if (favoritesState is FavoritesLoaded) {
      context.read<RecitersBloc>().add(
        ToggleFavoritesFilter(favoritesState.favoriteIds.toList()),
      );
      _scrollToTop();
    }
  }

  void _clearAllFilters() {
    _focusNode.unfocus();
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    context.read<RecitersBloc>().add(const ClearSearch());
    context.read<RecitersBloc>().add(const ClearLetterFilter());
    context.read<RecitersBloc>().add(const ClearFavoritesFilter());
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
    _scrollToTop();
  }

  Future<void> _refreshReciters() async {
    context.read<RecitersBloc>().add(const LoadReciters());
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('RecitersScreen');
    if (_isStartupLiteUi) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _RecitersStartupLitePane(),
            ),
          ],
        ),
      );
    }

    return BlocProvider.value(
      value: _favoritesCubit,
      child: Builder(
        builder: (innerContext) => MultiBlocListener(
          listeners: [
            BlocListener<LocalizationBloc, LocalizationState>(
              listener: (context, state) {
                _searchController.clear();
                context.read<AlphabetScrollbarBloc>().add(
                  const ClearSelection(),
                );
                context.read<RecitersBloc>().add(const LanguageChanged());
              },
            ),
            BlocListener<RecitersBloc, RecitersState>(
              listenWhen: (previous, current) =>
                  previous is! RecitersLoaded && current is RecitersLoaded,
              listener: (context, state) {
                _scheduleLoadedResultsActivation();
              },
            ),
            BlocListener<FavoritesCubit, FavoritesState>(
              listenWhen: (_, current) => current is FavoritesLoaded,
              listener: (context, state) {
                if (state is FavoritesLoaded) {
                  context.read<RecitersBloc>().add(
                    SyncFavoriteIds(state.favoriteIds.toList()),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<RecitersBloc, RecitersState>(
            buildWhen: (previous, current) {
              // Skip rebuild when only favoriteIds changed — _FavoriteButton
              // handles that independently via context.select<FavoritesCubit>.
              if (previous is RecitersLoaded && current is RecitersLoaded) {
                // Check if only favoriteIds changed (filteredReciters gets
                // re-sorted by _filterReciters but we don't need to rebuild)
                final onlyFavoritesChanged =
                    previous.favoriteIds != current.favoriteIds &&
                    previous.searchQuery == current.searchQuery &&
                    previous.selectedLetter == current.selectedLetter &&
                    previous.showFavoritesOnly == current.showFavoritesOnly;

                if (onlyFavoritesChanged) {
                  return false;
                }

                return previous.filteredReciters != current.filteredReciters ||
                    previous.searchQuery != current.searchQuery ||
                    previous.selectedLetter != current.selectedLetter ||
                    previous.showFavoritesOnly != current.showFavoritesOnly;
              }
              return true;
            },
            builder: (context, state) {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                body: _RecitersSliverScreen(
                  state: state,
                  allowHeavyLoadedResults: _allowHeavyLoadedResults,
                  searchController: _searchController,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  onSearchChanged: _onSearchChanged,
                  onClearSearch: _clearSearch,
                  onToggleFavorites: () => _toggleFavoritesFilter(innerContext),
                  onClearAll: _clearAllFilters,
                  onLetterSelected: _onLetterSelected,
                  onRetry: _refreshReciters,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecitersStartupLitePane extends StatelessWidget {
  const _RecitersStartupLitePane();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceExtraLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: tokens.iconSizeExtraLarge - tokens.spaceMedium,
              child: CircularProgressIndicator(
                strokeWidth: tokens.progressHeight,
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            Text(context.l10n.loadingReciters),
          ],
        ),
      ),
    );
  }
}

class _RecitersSliverScreen extends StatelessWidget {
  const _RecitersSliverScreen({
    required this.state,
    required this.allowHeavyLoadedResults,
    required this.searchController,
    required this.focusNode,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleFavorites,
    required this.onClearAll,
    required this.onLetterSelected,
    required this.onRetry,
  });

  final RecitersState state;
  final bool allowHeavyLoadedResults;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleFavorites;
  final VoidCallback onClearAll;
  final ValueChanged<String?> onLetterSelected;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('_RecitersSliverScreen');
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final double headerExtent = _recitersSearchHeaderExtent(context);
    const double scrollbarVerticalMargin = 10;
    final double scrollbarTopOffset = headerExtent + scrollbarVerticalMargin;
    final bool showScrollbar =
        state is RecitersLoaded &&
        allowHeavyLoadedResults &&
        (state as RecitersLoaded).filteredReciters.isNotEmpty &&
        (state as RecitersLoaded).searchQuery.isEmpty;

    return Stack(
      children: [
        Column(
          children: [
            _RecitersSearchHeaderBar(
              state: state,
              searchController: searchController,
              focusNode: focusNode,
              onSearchChanged: onSearchChanged,
              onClearSearch: onClearSearch,
              onToggleFavorites: onToggleFavorites,
            ),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: onRetry,
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _RecitersResultSection(
                      state: state,
                      allowHeavyLoadedResults: allowHeavyLoadedResults,
                      reserveScrollbarSpace: showScrollbar,
                      reserveScrollbarOnLeading: isRtl,
                      onClearAll: onClearAll,
                      onRetry: onRetry,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (showScrollbar)
          PositionedDirectional(
            top: scrollbarTopOffset,
            bottom: scrollbarVerticalMargin,
            start: isRtl ? tokens.spaceSmall : null,
            end: isRtl ? null : tokens.spaceSmall,
            child: ReciterAlphabetScrollbar(
              key: const ValueKey('alphabet_scrollbar'),
              allReciters: (state as RecitersLoaded).reciters,
              scrollController: scrollController,
              onLetterSelected: onLetterSelected,
            ),
          ),
      ],
    );
  }
}

class _RecitersResultSection extends StatelessWidget {
  const _RecitersResultSection({
    required this.state,
    required this.allowHeavyLoadedResults,
    required this.reserveScrollbarSpace,
    required this.reserveScrollbarOnLeading,
    required this.onClearAll,
    required this.onRetry,
  });

  final RecitersState state;
  final bool allowHeavyLoadedResults;
  final bool reserveScrollbarSpace;
  final bool reserveScrollbarOnLeading;
  final VoidCallback onClearAll;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (state is RecitersLoading) {
      return _RecitersSkeletonSection(
        reserveScrollbarSpace: reserveScrollbarSpace,
        reserveScrollbarOnLeading: reserveScrollbarOnLeading,
      );
    }

    if (state is RecitersError) {
      return _RecitersErrorSliver(
        failureMessage: (state as RecitersError).failure.localizedMessage(
          context,
        ),
        onRetry: onRetry,
      );
    }

    if (state is RecitersLoaded) {
      final RecitersLoaded loadedState = state as RecitersLoaded;

      if (!allowHeavyLoadedResults) {
        return _RecitersSkeletonSection(
          reserveScrollbarSpace: reserveScrollbarSpace,
          reserveScrollbarOnLeading: reserveScrollbarOnLeading,
        );
      }

      if (loadedState.filteredReciters.isEmpty) {
        return _RecitersEmptySliver(state: loadedState, onClearAll: onClearAll);
      }

      if (context.isCompact) {
        return _ReciterListSliver(
          state: loadedState,
          reserveScrollbarSpace: reserveScrollbarSpace,
          reserveScrollbarOnLeading: reserveScrollbarOnLeading,
        );
      }
      return _ReciterGridSliver(
        state: loadedState,
        reserveScrollbarSpace: reserveScrollbarSpace,
        reserveScrollbarOnLeading: reserveScrollbarOnLeading,
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}

class _RecitersSkeletonSection extends StatelessWidget {
  const _RecitersSkeletonSection({
    required this.reserveScrollbarSpace,
    required this.reserveScrollbarOnLeading,
  });

  final bool reserveScrollbarSpace;
  final bool reserveScrollbarOnLeading;

  @override
  Widget build(BuildContext context) {
    if (context.isCompact) {
      return _ReciterSkeletonListSliver(
        reserveScrollbarSpace: reserveScrollbarSpace,
        reserveScrollbarOnLeading: reserveScrollbarOnLeading,
      );
    }
    return ReciterSkeletonGridSliver(
      reserveScrollbarSpace: reserveScrollbarSpace,
      reserveScrollbarOnLeading: reserveScrollbarOnLeading,
      itemCount: 10,
    );
  }
}

class _RecitersErrorSliver extends StatelessWidget {
  const _RecitersErrorSliver({
    required this.failureMessage,
    required this.onRetry,
  });

  final String failureMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: StatePanel(
        key: const ValueKey('error_state'),
        icon: Icons.error_outline_rounded,
        title: failureMessage,
        actionLabel: context.l10n.retry,
        onAction: onRetry,
        isError: true,
      ),
    );
  }
}

class _RecitersEmptySliver extends StatelessWidget {
  const _RecitersEmptySliver({required this.state, required this.onClearAll});

  final RecitersLoaded state;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final bool isSearchState = state.searchQuery.isNotEmpty;
    final bool isFavoritesState = state.showFavoritesOnly;
    final bool hasActiveFilters = _hasActiveFilters(state);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: StatePanel(
        key: const ValueKey('empty_state'),
        icon: isFavoritesState
            ? Icons.favorite_border_rounded
            : Icons.search_off_rounded,
        title: isFavoritesState
            ? context.l10n.noFavorites
            : isSearchState
            ? context.l10n.noSearchResults
            : context.l10n.noRecitersFound,
        subtitle: isSearchState ? context.l10n.tryDifferentSearch : null,
        actionLabel: hasActiveFilters ? context.l10n.clearAll : null,
        onAction: hasActiveFilters ? onClearAll : null,
      ),
    );
  }
}

class _RecitersSearchHeaderBar extends StatelessWidget {
  const _RecitersSearchHeaderBar({
    required this.state,
    required this.searchController,
    required this.focusNode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleFavorites,
  });

  final RecitersState state;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleFavorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double searchFieldHeight = theme.componentTokens.searchField.height;

    return SizedBox(
      height: _recitersSearchHeaderExtent(context),
      child: Material(
        color: theme.colorScheme.primary,
        child: Padding(
          padding: EdgeInsets.only(top: context.contentTopSafePadding),
          child: Center(
            child: SizedBox(
              height: searchFieldHeight,
              child: _ConstrainedHeaderContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SearchField(
                          controller: searchController,
                          focusNode: focusNode,
                          onChanged: onSearchChanged,
                          onClear: onClearSearch,
                        ),
                      ),
                      SizedBox(width: tokens.spaceSmall),
                      _FavoritesToggle(state: state, onTap: onToggleFavorites),
                      SizedBox(width: tokens.spaceSmall),
                      const _DownloadsButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConstrainedHeaderContent extends StatelessWidget {
  const _ConstrainedHeaderContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Theme.of(context).tokens.contentMaxWidthMedia,
        ),
        child: child,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: ReciterSemanticsIds.recitersSearchField,
      child: TilawaSearchField(
        controller: controller,
        focusNode: focusNode,
        hintText: context.l10n.searchReciters,
        prefixIcon: FluentIcons.search_24_regular,
        clearIcon: FluentIcons.dismiss_24_regular,
        onChanged: onChanged,
        onClear: onClear,
        borderRadius: BorderRadius.circular(
          Theme.of(context).tokens.radiusLarge,
        ),
        showShadow: true,
        onTapOutside: (_) => focusNode.unfocus(),
      ),
    );
  }
}

class _FavoritesToggle extends StatelessWidget {
  const _FavoritesToggle({required this.state, required this.onTap});

  final RecitersState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final bool isActive =
        state is RecitersLoaded && (state as RecitersLoaded).showFavoritesOnly;

    return Semantics(
      identifier: ReciterSemanticsIds.recitersFavoritesToggle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TilawaIconActionButton(
            icon: isActive
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            isActive: isActive,
            onTap: onTap,
          ),
          PositionedDirectional(
            top: -tokens.spaceExtraSmall,
            end: -tokens.spaceExtraSmall,
            child: BlocBuilder<FavoritesCubit, FavoritesState>(
              builder: (context, favoritesState) {
                final int count = favoritesState is FavoritesLoaded
                    ? favoritesState.favoriteIds.length
                    : 0;
                if (count == 0) {
                  return const SizedBox.shrink();
                }

                return Container(
                  constraints: BoxConstraints(
                    minWidth: tokens.iconSizeMedium - tokens.spaceTiny,
                    minHeight: tokens.iconSizeMedium - tokens.spaceTiny,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceExtraSmall + tokens.spaceTiny,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.surface
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(
                      tokens.radiusExtraLarge,
                    ),
                    border: Border.all(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      width: tokens.borderWidthThin + tokens.borderWidthThin,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadsButton extends StatelessWidget {
  const _DownloadsButton();

  @override
  Widget build(BuildContext context) {
    return TilawaIconActionButton(
      icon: FluentIcons.arrow_download_24_regular,
      onTap: () => const DownloadsRoute().push(context),
    );
  }
}

class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color accent = isError
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceExtraLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: tokens.iconSizeExtraLarge + tokens.spaceExtraLarge,
              height: tokens.iconSizeExtraLarge + tokens.spaceExtraLarge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.1),
              ),
              child: isLoading
                  ? Padding(
                      padding: EdgeInsets.all(
                        tokens.spaceLarge + tokens.spaceExtraSmall,
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: tokens.progressHeight,
                        color: accent,
                      ),
                    )
                  : Icon(
                      icon,
                      size: tokens.iconSizeExtraLarge - tokens.spaceLarge,
                      color: accent,
                    ),
            ),
            SizedBox(height: tokens.spaceMedium + tokens.spaceTiny),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isError ? accent : theme.colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: tokens.spaceSmall),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: tokens.spaceLarge),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReciterListSliver extends StatelessWidget {
  const _ReciterListSliver({
    required this.state,
    required this.reserveScrollbarSpace,
    required this.reserveScrollbarOnLeading,
  });

  final RecitersLoaded state;
  final bool reserveScrollbarSpace;
  final bool reserveScrollbarOnLeading;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('_ReciterListSliver');
    final tokens = Theme.of(context).tokens;
    final int reciterCount = state.filteredReciters.length;
    final int itemCount = reciterCount + reciterCount - 1;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final padding = _recitersResultPadding(
          context,
          constraints,
          top: tokens.spaceSmall,
          bottom: tokens.spaceLarge,
          reserveScrollbarSpace: reserveScrollbarSpace,
          reserveScrollbarOnLeading: reserveScrollbarOnLeading,
        );

        return SliverPadding(
          padding: padding,
          sliver: SliverList.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index.isOdd) {
                return SizedBox(height: tokens.spaceSmall);
              }

              final ReciterEntity reciter = state.filteredReciters[index ~/ 2];
              return ReciterCard(key: ValueKey(reciter.id), reciter: reciter);
            },
          ),
        );
      },
    );
  }
}

class _ReciterGridSliver extends StatelessWidget {
  const _ReciterGridSliver({
    required this.state,
    required this.reserveScrollbarSpace,
    required this.reserveScrollbarOnLeading,
  });

  final RecitersLoaded state;
  final bool reserveScrollbarSpace;
  final bool reserveScrollbarOnLeading;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('_ReciterGridSliver');
    final tokens = Theme.of(context).tokens;
    final double targetItemExtent =
        tokens.cardCompactWidthThreshold +
        tokens.spaceExtraLarge +
        tokens.spaceLarge;
    final double targetItemHeight =
        tokens.playerCollapsedHeight + tokens.spaceExtraLarge;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final padding = _recitersResultPadding(
          context,
          constraints,
          top: tokens.spaceSmall,
          bottom: tokens.spaceLarge,
          reserveScrollbarSpace: reserveScrollbarSpace,
          reserveScrollbarOnLeading: reserveScrollbarOnLeading,
        );

        return SliverPadding(
          padding: padding,
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: targetItemExtent,
              mainAxisSpacing: tokens.spaceSmall + tokens.spaceTiny,
              crossAxisSpacing: tokens.spaceSmall + tokens.spaceTiny,
              childAspectRatio: targetItemExtent / targetItemHeight,
            ),
            itemCount: state.filteredReciters.length,
            itemBuilder: (context, index) {
              final ReciterEntity reciter = state.filteredReciters[index];
              return ReciterCard(key: ValueKey(reciter.id), reciter: reciter);
            },
          ),
        );
      },
    );
  }
}

ReciterEntity _fakeReciter(int index) {
  return ReciterEntity(
    id: index,
    name: 'Reciter Name',
    letter: 'ا',
    date: '2024-01-01',
    moshaf: const [
      MoshafEntity(
        id: 1,
        name: 'Hafs An Asim',
        server: 'server',
        surahTotal: 114,
        moshafType: 1,
        surahList: '1-114',
      ),
    ],
  );
}

class _ReciterSkeletonListSliver extends StatelessWidget {
  const _ReciterSkeletonListSliver({
    required this.reserveScrollbarSpace,
    required this.reserveScrollbarOnLeading,
  });

  final bool reserveScrollbarSpace;
  final bool reserveScrollbarOnLeading;
  final int itemCount = 10;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('_ReciterSkeletonListSliver');
    final tokens = Theme.of(context).tokens;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final padding = _recitersResultPadding(
          context,
          constraints,
          top: tokens.spaceSmall,
          bottom: tokens.spaceLarge,
          reserveScrollbarSpace: reserveScrollbarSpace,
          reserveScrollbarOnLeading: reserveScrollbarOnLeading,
        );

        return SliverPadding(
          padding: padding,
          sliver: SliverSkeletonizer(
            child: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index.isOdd) {
                  return SizedBox(height: tokens.spaceSmall);
                }
                final reciter = _fakeReciter(index ~/ 2);
                return ReciterCard(key: ValueKey(reciter.id), reciter: reciter);
              }, childCount: itemCount + itemCount - 1),
            ),
          ),
        );
      },
    );
  }
}

class ReciterSkeletonGridSliver extends StatelessWidget {
  const ReciterSkeletonGridSliver({
    super.key,
    required this.reserveScrollbarSpace,
    required this.reserveScrollbarOnLeading,
    required this.itemCount,
  });

  final bool reserveScrollbarSpace;
  final bool reserveScrollbarOnLeading;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('_ReciterSkeletonGridSliver');
    final tokens = Theme.of(context).tokens;
    final double targetItemExtent =
        tokens.cardCompactWidthThreshold +
        tokens.spaceExtraLarge +
        tokens.spaceLarge;
    final double targetItemHeight =
        tokens.playerCollapsedHeight + tokens.spaceExtraLarge;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final padding = _recitersResultPadding(
          context,
          constraints,
          top: tokens.spaceSmall,
          bottom: tokens.spaceLarge,
          reserveScrollbarSpace: reserveScrollbarSpace,
          reserveScrollbarOnLeading: reserveScrollbarOnLeading,
        );

        return SliverPadding(
          padding: padding,
          sliver: SliverSkeletonizer(
            child: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: targetItemExtent,
                mainAxisSpacing: tokens.spaceSmall + tokens.spaceTiny,
                crossAxisSpacing: tokens.spaceSmall + tokens.spaceTiny,
                childAspectRatio: targetItemExtent / targetItemHeight,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final reciter = _fakeReciter(index);
                return ReciterCard(key: ValueKey(reciter.id), reciter: reciter);
              }, childCount: itemCount),
            ),
          ),
        );
      },
    );
  }
}

class ReciterAlphabetScrollbar extends StatefulWidget {
  const ReciterAlphabetScrollbar({
    super.key,
    required this.allReciters,
    required this.scrollController,
    required this.onLetterSelected,
  });
  final List<ReciterEntity> allReciters;
  final ScrollController scrollController;
  final Function(String? letter) onLetterSelected;

  @override
  State<ReciterAlphabetScrollbar> createState() =>
      _ReciterAlphabetScrollbarState();
}

class _ReciterAlphabetScrollbarState extends State<ReciterAlphabetScrollbar> {
  late List<String> _letters;

  @override
  void initState() {
    super.initState();
    _letters = _extractLetters(widget.allReciters);
  }

  @override
  void didUpdateWidget(covariant ReciterAlphabetScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recalculate letters if reciters actually changed
    if (widget.allReciters.length != oldWidget.allReciters.length ||
        widget.allReciters.isEmpty != oldWidget.allReciters.isEmpty) {
      _letters = _extractLetters(widget.allReciters);
    }
  }

  List<String> _extractLetters(List<ReciterEntity> reciters) {
    return reciters.map((r) => r.letter).toSet().toList()..sort();
  }

  void _handleLetterSelection(String? letter) {
    if (letter == null) {
      context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
      widget.onLetterSelected(null);
      return;
    }

    context.read<AlphabetScrollbarBloc>().add(SelectLetter(letter));

    final int index = widget.allReciters.indexWhere(
      (item) => item.letter == letter,
    );
    if (index != -1) {
      widget.scrollController.jumpTo(0.0);
    }

    widget.onLetterSelected(letter);
  }

  @override
  Widget build(BuildContext context) {
    if (_letters.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedLetter = context
        .watch<AlphabetScrollbarBloc>()
        .state
        .selectedLetter;

    return ArabicAlphabetScrollbar(
      key: const ValueKey('alphabet_scrollbar'),
      letters: _letters,
      selectedLetter: selectedLetter,
      onLetterSelected: _handleLetterSelection,
      onPanStart: (_) =>
          context.read<AlphabetScrollbarBloc>().add(const StartDragging()),
      onPanUpdate: (_) {},
      onPanEnd: (_) =>
          context.read<AlphabetScrollbarBloc>().add(const EndDragging()),
      onLongPressStart: (details) =>
          context.read<AlphabetScrollbarBloc>().add(const StartDragging()),
      onLongPressMoveUpdate: (details) {},
      onLongPressEnd: (_) =>
          context.read<AlphabetScrollbarBloc>().add(const EndDragging()),
    );
  }
}

double _recitersSearchHeaderExtent(BuildContext context) {
  final theme = Theme.of(context);
  final topPadding = context.contentTopSafePadding;
  return theme.componentTokens.searchField.height +
      topPadding +
      (theme.tokens.spaceMedium * 2);
}

EdgeInsetsGeometry _recitersResultPadding(
  BuildContext context,
  SliverConstraints constraints, {
  required double top,
  required double bottom,
  required bool reserveScrollbarSpace,
  required bool reserveScrollbarOnLeading,
}) {
  final theme = Theme.of(context);
  final tokens = theme.tokens;
  final double centeredInset = math.max(
    tokens.spaceMedium,
    ((constraints.crossAxisExtent - tokens.contentMaxWidthMedia) / 2) +
        tokens.spaceMedium,
  );
  final double scrollbarInset = reserveScrollbarSpace
      ? theme.componentTokens.alphabetScrollbar.width + tokens.spaceSmall
      : 0;

  return EdgeInsetsDirectional.fromSTEB(
    centeredInset + (reserveScrollbarOnLeading ? scrollbarInset : 0),
    top,
    centeredInset + (reserveScrollbarOnLeading ? 0 : scrollbarInset),
    bottom,
  );
}

bool _hasActiveFilters(RecitersLoaded state) {
  return state.searchQuery.isNotEmpty ||
      state.selectedLetter != null ||
      state.showFavoritesOnly;
}
