import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_card.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import '../bloc/reciters_bloc.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

enum _RecitersMenuAction { clearFavorites }

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 200);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecitersBloc>().add(const LoadReciters());
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  Future<void> _showClearFavoritesDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.clearFavorites),
        content: Text(context.l10n.clearFavoritesConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.l10n.clearAll,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted || !(confirmed ?? false)) {
      return;
    }

    final bool cleared = await context
        .read<FavoritesCubit>()
        .clearAllFavorites();
    if (!context.mounted) {
      return;
    }

    if (!cleared) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.anErrorOccurred)));
      return;
    }

    final RecitersState recitersState = context.read<RecitersBloc>().state;
    if (recitersState is RecitersLoaded && recitersState.showFavoritesOnly) {
      context.read<RecitersBloc>().add(const ClearFavoritesFilter());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FavoritesCubit>()..loadFavorites(),
      child: Builder(
        builder: (innerContext) => MultiBlocListener(
          listeners: [
            BlocListener<LocalizationBloc, LocalizationState>(
              listener: (context, state) {
                context.read<RecitersBloc>().add(const LanguageChanged());
              },
            ),
            BlocListener<RecitersBloc, RecitersState>(
              listenWhen: (previous, current) =>
                  previous is! RecitersLoaded && current is RecitersLoaded,
              listener: (context, state) {
                final String? selectedLetter = context
                    .read<AlphabetScrollbarBloc>()
                    .state
                    .selectedLetter;
                final FavoritesState favoritesState = context
                    .read<FavoritesCubit>()
                    .state;

                if (favoritesState is FavoritesLoaded) {
                  context.read<RecitersBloc>().add(
                    SyncFavoriteIds(favoritesState.favoriteIds.toList()),
                  );
                }

                if (selectedLetter != null) {
                  context.read<RecitersBloc>().add(
                    FilterByLetter(selectedLetter),
                  );
                }
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
              final l10n = context.l10n;

              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  title: Text(l10n.reciters),
                  actions: [
                    IconButton(
                      icon: const Icon(FluentIcons.bookmark_24_regular),
                      tooltip: l10n.bookmarks,
                      onPressed: () => const BookmarksRoute().push(context),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.history_24_regular),
                      tooltip: l10n.listeningHistory,
                      onPressed: () => const HistoryRoute().push(context),
                    ),
                    BlocBuilder<FavoritesCubit, FavoritesState>(
                      builder: (context, favoritesState) {
                        final bool hasFavorites =
                            favoritesState is FavoritesLoaded &&
                            favoritesState.favoriteIds.isNotEmpty;
                        if (!hasFavorites) {
                          return const SizedBox.shrink();
                        }

                        return PopupMenuButton<_RecitersMenuAction>(
                          tooltip: l10n.clearFavorites,
                          onSelected: (action) {
                            if (action == _RecitersMenuAction.clearFavorites) {
                              _showClearFavoritesDialog(innerContext);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<_RecitersMenuAction>(
                              value: _RecitersMenuAction.clearFavorites,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_sweep_rounded,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(l10n.clearFavorites),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: _RecitersSurface(
                    state: state,
                    searchController: _searchController,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    onSearchChanged: _onSearchChanged,
                    onClearSearch: _clearSearch,
                    onToggleFavorites: () =>
                        _toggleFavoritesFilter(innerContext),
                    onClearLetter: _clearLetterFilter,
                    onClearFavorites: () {
                      context.read<RecitersBloc>().add(
                        const ClearFavoritesFilter(),
                      );
                    },
                    onClearAll: _clearAllFilters,
                    onLetterSelected: _onLetterSelected,
                    onRetry: _refreshReciters,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecitersSurface extends StatelessWidget {
  const _RecitersSurface({
    required this.state,
    required this.searchController,
    required this.focusNode,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleFavorites,
    required this.onClearLetter,
    required this.onClearFavorites,
    required this.onClearAll,
    required this.onLetterSelected,
    required this.onRetry,
  });

  final RecitersState state;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleFavorites;
  final VoidCallback onClearLetter;
  final VoidCallback onClearFavorites;
  final VoidCallback onClearAll;
  final ValueChanged<String?> onLetterSelected;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
        // Removed expensive boxShadow to reduce raster jank
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SearchField(
                          controller: searchController,
                          focusNode: focusNode,
                          onChanged: onSearchChanged,
                          onClear: onClearSearch,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FavoritesToggle(state: state, onTap: onToggleFavorites),
                      const SizedBox(width: 8),
                      const _DownloadsButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ResultsSummary(state: state),
                  Builder(
                    builder: (context) {
                      if (state is! RecitersLoaded) {
                        return const SizedBox.shrink();
                      }
                      final loadedState = state as RecitersLoaded;
                      if (!_hasActiveFilters(loadedState)) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _ActiveFiltersBar(
                          state: loadedState,
                          onClearSearch: onClearSearch,
                          onClearLetter: onClearLetter,
                          onClearFavorites: onClearFavorites,
                          onClearAll: onClearAll,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _ResultsPane(
                state: state,
                scrollController: scrollController,
                onLetterSelected: onLetterSelected,
                onRetry: onRetry,
                onClearFilters: onClearAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.state});

  final RecitersState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title = switch (state) {
      RecitersLoaded loadedState =>
        loadedState.filteredReciters.length == loadedState.reciters.length
            ? '${loadedState.reciters.length} ${context.l10n.reciters}'
            : '${loadedState.filteredReciters.length} / ${loadedState.reciters.length} ${context.l10n.reciters}',
      RecitersLoading() => context.l10n.loadingReciters,
      RecitersError() => context.l10n.reciters,
      _ => context.l10n.reciters,
    };

    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
    return TilawaSearchField(
      controller: controller,
      focusNode: focusNode,
      hintText: context.l10n.searchReciters,
      prefixIcon: FluentIcons.search_24_regular,
      clearIcon: FluentIcons.dismiss_24_regular,
      onChanged: onChanged,
      onClear: onClear,
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      showShadow: true,
      onTapOutside: (_) => focusNode.unfocus(),
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
    final bool isActive =
        state is RecitersLoaded && (state as RecitersLoaded).showFavoritesOnly;

    return Stack(
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
          top: -4,
          end: -4,
          child: BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, favoritesState) {
              final int count = favoritesState is FavoritesLoaded
                  ? favoritesState.favoriteIds.length
                  : 0;
              if (count == 0) {
                return const SizedBox.shrink();
              }

              return Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : theme.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isActive ? theme.primaryColor : Colors.white,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive ? theme.primaryColor : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({
    required this.state,
    required this.onClearSearch,
    required this.onClearLetter,
    required this.onClearFavorites,
    required this.onClearAll,
  });

  final RecitersLoaded state;
  final VoidCallback onClearSearch;
  final VoidCallback onClearLetter;
  final VoidCallback onClearFavorites;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (state.searchQuery.isNotEmpty)
            _FilterChip(
              icon: Icons.search_rounded,
              label: state.searchQuery,
              onClear: onClearSearch,
            ),
          if (state.selectedLetter != null)
            _FilterChip(
              icon: Icons.filter_alt_rounded,
              label: state.selectedLetter!,
              onClear: onClearLetter,
            ),
          if (state.showFavoritesOnly)
            _FilterChip(
              icon: Icons.favorite_rounded,
              label: context.l10n.favorites,
              onClear: onClearFavorites,
            ),
          ActionChip(label: Text(context.l10n.clearAll), onPressed: onClearAll),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(icon, size: 16),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
      onDeleted: onClear,
    );
  }
}

class _ResultsPane extends StatelessWidget {
  const _ResultsPane({
    required this.state,
    required this.scrollController,
    required this.onLetterSelected,
    required this.onRetry,
    required this.onClearFilters,
  });

  final RecitersState state;
  final ScrollController scrollController;
  final ValueChanged<String?> onLetterSelected;
  final Future<void> Function() onRetry;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    // Skip AnimatedSwitcher for loaded state to avoid jank when filtering
    return _buildChild(context);
  }

  Widget _buildChild(BuildContext context) {
    if (state is RecitersLoading) {
      return _StatePanel(
        key: const ValueKey('loading_state'),
        icon: Icons.hourglass_top_rounded,
        title: context.l10n.loadingReciters,
        isLoading: true,
      );
    }

    if (state is RecitersError) {
      return _StatePanel(
        key: const ValueKey('error_state'),
        icon: Icons.error_outline_rounded,
        title: (state as RecitersError).message,
        actionLabel: context.l10n.retry,
        onAction: () {
          onRetry();
        },
        isError: true,
      );
    }

    if (state is RecitersLoaded) {
      final RecitersLoaded loadedState = state as RecitersLoaded;

      if (loadedState.filteredReciters.isEmpty) {
        final bool isSearchState = loadedState.searchQuery.isNotEmpty;
        final bool isFavoritesState = loadedState.showFavoritesOnly;

        return _StatePanel(
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
          actionLabel: _hasActiveFilters(loadedState)
              ? context.l10n.clearAll
              : null,
          onAction: _hasActiveFilters(loadedState) ? onClearFilters : null,
        );
      }

      return _LoadedResults(
        key: const ValueKey('loaded_state'),
        state: loadedState,
        scrollController: scrollController,
        onLetterSelected: onLetterSelected,
        onRefresh: onRetry,
      );
    }

    return const SizedBox.shrink(key: ValueKey('fallback_state'));
  }
}

class _LoadedResults extends StatelessWidget {
  const _LoadedResults({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onLetterSelected,
    required this.onRefresh,
  });

  final RecitersLoaded state;
  final ScrollController scrollController;
  final ValueChanged<String?> onLetterSelected;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bool showScrollbar =
        state.filteredReciters.isNotEmpty && state.searchQuery.isEmpty;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    // Memoize scrollbar with stable identity to prevent rebuilds during filtering
    final scrollbar = showScrollbar
        ? ReciterAlphabetScrollbar(
            key: const ValueKey('alphabet_scrollbar'),
            // Use allReciters (unfiltered) so letters stay stable during filtering
            allReciters: state.reciters,
            scrollController: scrollController,
            onLetterSelected: onLetterSelected,
          )
        : const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRtl && showScrollbar) scrollbar,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 980) {
                return _ReciterGridView(
                  state: state,
                  scrollController: scrollController,
                  crossAxisCount: 3,
                  onRefresh: onRefresh,
                );
              }
              if (constraints.maxWidth >= 680) {
                return _ReciterGridView(
                  state: state,
                  scrollController: scrollController,
                  crossAxisCount: 2,
                  onRefresh: onRefresh,
                );
              }
              return _ReciterListView(
                state: state,
                scrollController: scrollController,
                onRefresh: onRefresh,
              );
            },
          ),
        ),
        if (!isRtl && showScrollbar) scrollbar,
      ],
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
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
    final Color accent = isError
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.1),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: accent,
                      ),
                    )
                  : Icon(icon, size: 32, color: accent),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isError ? accent : theme.colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
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

class _ReciterListView extends StatelessWidget {
  const _ReciterListView({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
  });

  final RecitersLoaded state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: state.filteredReciters.length,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final ReciterEntity reciter = state.filteredReciters[index];
          return ReciterCard(key: ValueKey(reciter.id), reciter: reciter);
        },
      ),
    );
  }
}

class _ReciterGridView extends StatelessWidget {
  const _ReciterGridView({
    required this.state,
    required this.scrollController,
    required this.crossAxisCount,
    required this.onRefresh,
  });

  final RecitersLoaded state;
  final ScrollController scrollController;
  final int crossAxisCount;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: GridView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 104,
        ),
        itemCount: state.filteredReciters.length,
        itemBuilder: (context, index) {
          final ReciterEntity reciter = state.filteredReciters[index];
          return ReciterCard(key: ValueKey(reciter.id), reciter: reciter);
        },
      ),
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

  void _handleLetterTap(String letter, AlphabetScrollbarState currentState) {
    if (currentState.selectedLetter == letter) {
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

  void _handlePanUpdate(
    DragUpdateDetails details,
    AlphabetScrollbarState currentState,
  ) {
    if (!currentState.isDragging) return;

    final box = context.findRenderObject()! as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final letterHeight = box.size.height / _letters.length;
    final letterIndex = (localPosition.dy / letterHeight)
        .clamp(0, _letters.length - 1)
        .floor();

    if (letterIndex >= 0 && letterIndex < _letters.length) {
      final String letter = _letters[letterIndex];
      if (currentState.selectedLetter != letter) {
        context.read<AlphabetScrollbarBloc>().add(UpdateDragLetter(letter));

        final int index = widget.allReciters.indexWhere(
          (item) => item.letter == letter,
        );
        if (index != -1) {
          widget.scrollController.jumpTo(0.0);
        }

        widget.onLetterSelected(letter);
      }
    }
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
      onLetterSelected: (letter) =>
          _handleLetterTap(letter, context.read<AlphabetScrollbarBloc>().state),
      onPanStart: (_) =>
          context.read<AlphabetScrollbarBloc>().add(const StartDragging()),
      onPanUpdate: (details) => _handlePanUpdate(
        details,
        context.read<AlphabetScrollbarBloc>().state,
      ),
      onPanEnd: (_) =>
          context.read<AlphabetScrollbarBloc>().add(const EndDragging()),
    );
  }
}

bool _hasActiveFilters(RecitersLoaded state) {
  return state.searchQuery.isNotEmpty ||
      state.selectedLetter != null ||
      state.showFavoritesOnly;
}
