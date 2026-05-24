import 'dart:async';
import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciter_list_moshaf_label.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_card.dart';
import 'package:tilawa/features/tour_guide/presentation/widgets/tour_target.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../../../screens/cubit/main_screen_cubit.dart';
import '../../../../screens/cubit/main_screen_state.dart';
import '../../../../shared/widgets/quran_player_chrome.dart';
import '../../../../shared/widgets/quran_player_system_back.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import '../bloc/reciters_bloc.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../reciter_semantics_ids.dart';
import '../tour/reciters_tour_launcher.dart';
import '../tour/reciters_tour_targets.dart';

/// Main-shell system back: collapse expanded player, tab focus, then exit.
///
/// Wrap [MainTabViewport] (not individual tab caches) so [PopScope.canPop]
/// updates when [MainScreenCubit.currentIndex] changes. A [PopScope] inside
/// offstage [RecitersScreen] would stay stale and allow exit from other tabs.
class RecitersRootBackScope extends StatelessWidget {
  const RecitersRootBackScope({super.key, required this.child});

  final Widget child;

  static bool canExitApp(int mainTabIndex) {
    if (mainTabIndex != 0) {
      return false;
    }
    return QuranPlayerRoutePolicy.isMainShell(
      QuranPlayerRoutePolicy.currentMatchedLocation(),
    );
  }

  static bool canPop(int mainTabIndex) {
    if (QuranPlayerSystemBackCoordinator.interceptsSystemBack) {
      return false;
    }
    return canExitApp(mainTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MainScreenCubit, MainScreenState, int>(
      selector: (MainScreenState state) => state.currentIndex,
      builder: (BuildContext context, int tabIndex) {
        return PopScope(
          canPop: canPop(tabIndex),
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) {
              return;
            }
            if (QuranPlayerSystemBackCoordinator.interceptsSystemBack) {
              QuranPlayerSystemBackCoordinator.handleSystemBack();
              return;
            }
            if (tabIndex != 0) {
              context.read<MainScreenCubit>().selectTab(0);
            }
          },
          child: child,
        );
      },
    );
  }
}

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
  bool _showLetterIndex = false;
  bool _letterIndexDefaultResolved = false;
  bool _introTourAttempted = false;
  late final FavoritesCubit _favoritesCubit;

  @override
  void initState() {
    super.initState();
    _favoritesCubit = getIt<FavoritesCubit>();
    final RecitersBloc recitersBloc = context.read<RecitersBloc>();
    final RecitersState startupState = recitersBloc.state;

    if (startupState is RecitersLoaded) {
      _isStartupLiteUi = false;
      _allowHeavyLoadedResults = true;
      _favoritesCubit.loadFavorites();
      _scheduleRecitersIntroTour();
      return;
    }

    if (startupState is RecitersLoading) {
      _isStartupLiteUi = false;
      _favoritesCubit.loadFavorites();
      return;
    }

    _startupLiteUiTimer = Timer(_startupLiteUiDuration, () {
      if (!mounted) return;
      setState(() {
        _isStartupLiteUi = false;
      });
      _favoritesCubit.loadFavorites();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        '[AppLaunch] source=RecitersScreen initial-load scheduled '
        'delayMs=${_initialRecitersLoadDelay.inMilliseconds}',
      );
      _initialLoadTimer = Timer(_initialRecitersLoadDelay, () {
        if (!mounted) return;
        debugPrint('[AppLaunch] source=RecitersScreen initial-load started');
        recitersBloc.add(const LoadReciters());
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
      _scheduleRecitersIntroTour();
    });
  }

  void _scheduleRecitersIntroTour() {
    if (_introTourAttempted || !_allowHeavyLoadedResults) {
      return;
    }
    final RecitersState state = context.read<RecitersBloc>().state;
    if (state is! RecitersLoaded || state.filteredReciters.isEmpty) {
      return;
    }
    _introTourAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) {
          return;
        }
        final RecitersState latest = context.read<RecitersBloc>().state;
        if (latest is! RecitersLoaded || latest.filteredReciters.isEmpty) {
          return;
        }
        unawaited(getIt<RecitersTourLauncher>().maybeShowRecitersIntro(context));
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
      duration: context.tokens.durationFast,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_letterIndexDefaultResolved) {
      return;
    }
    _letterIndexDefaultResolved = true;
    _showLetterIndex =
        MediaQuery.sizeOf(context).width >=
        kRecitersAlphabetDefaultVisibleBreakpoint;
  }

  void _toggleLetterIndex() {
    setState(() {
      _showLetterIndex = !_showLetterIndex;
    });
    if (!_showLetterIndex) {
      _clearLetterFilter();
    }
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
      final ColorScheme colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colorScheme.surface,
        appBar: TilawaCatalogAppBar.titleOnly(
          context,
          title: context.l10n.reciters,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _RecitersAmbientBackground(),
            CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                const _DryLayoutSafeFillSliver(
                  child: _RecitersStartupLitePane(),
                ),
              ],
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
                  if (_allowHeavyLoadedResults) {
                    _scheduleRecitersIntroTour();
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

                  return previous.filteredReciters !=
                          current.filteredReciters ||
                      previous.searchQuery != current.searchQuery ||
                      previous.selectedLetter != current.selectedLetter ||
                      previous.showFavoritesOnly != current.showFavoritesOnly;
                }
                return true;
              },
              builder: (context, state) {
                final bool letterIndexAvailable =
                    state is RecitersLoaded &&
                    _allowHeavyLoadedResults &&
                    state.filteredReciters.isNotEmpty &&
                    state.searchQuery.isEmpty;
                final ColorScheme colorScheme =
                    Theme.of(context).colorScheme;

                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: colorScheme.surface,
                  appBar: _RecitersTilawaAppBar(
                      bottomHeight:
                          TilawaAppBarConfig.catalogTitleSearchAndFilterRowHeight(
                        context,
                      ),
                      state: state,
                      letterIndexAvailable: letterIndexAvailable,
                      showLetterIndex: _showLetterIndex,
                      searchController: _searchController,
                      focusNode: _focusNode,
                      onSearchChanged: _onSearchChanged,
                      onClearSearch: _clearSearch,
                      onToggleFavorites: () =>
                          _toggleFavoritesFilter(innerContext),
                      onToggleLetterIndex: _toggleLetterIndex,
                      onClearFavoritesFilter: () {
                        context.read<RecitersBloc>().add(
                          const ClearFavoritesFilter(),
                        );
                        _scrollToTop();
                      },
                      onClearLetterFilter: _clearLetterFilter,
                      onClearAllFilters: _clearAllFilters,
                    ),
                  body: _RecitersSliverScreen(
                    state: state,
                    allowHeavyLoadedResults: _allowHeavyLoadedResults,
                    showLetterIndex: _showLetterIndex,
                    scrollController: _scrollController,
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
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceExtraLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: tokens.iconSizeExtraLarge,
              child: TilawaLoadingIndicator(
                centered: false,
                strokeWidth: tokens.progressHeight,
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            Text(
              context.l10n.loadingReciters,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
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
    required this.showLetterIndex,
    required this.scrollController,
    required this.onClearAll,
    required this.onLetterSelected,
    required this.onRetry,
  });

  final RecitersState state;
  final bool allowHeavyLoadedResults;
  final bool showLetterIndex;
  final ScrollController scrollController;
  final VoidCallback onClearAll;
  final ValueChanged<String?> onLetterSelected;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('_RecitersSliverScreen');
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    const double letterIndexVerticalMargin = 8;
    final bool letterIndexAvailable =
        state is RecitersLoaded &&
        allowHeavyLoadedResults &&
        (state as RecitersLoaded).filteredReciters.isNotEmpty &&
        (state as RecitersLoaded).searchQuery.isEmpty;
    final bool showLetterIndexRail = letterIndexAvailable && showLetterIndex;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: _RecitersAmbientBackground()),
        RefreshIndicator.adaptive(
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
                reserveScrollbarSpace: showLetterIndexRail,
                reserveScrollbarOnLeading: isRtl,
                onClearAll: onClearAll,
                onRetry: onRetry,
              ),
            ],
          ),
        ),
        if (showLetterIndexRail)
          _RecitersLetterIndexGutter(
            isRtl: isRtl,
            verticalMargin: letterIndexVerticalMargin,
            reciters: (state as RecitersLoaded).reciters,
            scrollController: scrollController,
            onLetterSelected: onLetterSelected,
            scrollbarSemanticsLabel: context.l10n.a11yRecitersLetterIndex,
            scrollbarSemanticsHint:
                context.l10n.a11yRecitersAlphabetScrollbarHint,
          ),
      ],
    );
  }
}

/// Letter-index rail pinned to the trailing screen edge (Pinterest-style).
///
/// The list body already sits below [Scaffold.appBar]; do not offset this rail
/// by app-bar height again or it will overlap reciter rows.
class _RecitersLetterIndexGutter extends StatelessWidget {
  const _RecitersLetterIndexGutter({
    required this.isRtl,
    required this.verticalMargin,
    required this.reciters,
    required this.scrollController,
    required this.onLetterSelected,
    required this.scrollbarSemanticsLabel,
    required this.scrollbarSemanticsHint,
  });

  final bool isRtl;
  final double verticalMargin;
  final List<ReciterEntity> reciters;
  final ScrollController scrollController;
  final ValueChanged<String?> onLetterSelected;
  final String? scrollbarSemanticsLabel;
  final String? scrollbarSemanticsHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double gutterWidth = _recitersLetterIndexGutterWidth(theme);
    final double scrollbarWidth =
        theme.componentTokens.alphabetScrollbar.width;

    return PositionedDirectional(
      top: verticalMargin,
      bottom: verticalMargin,
      start: isRtl ? 0 : null,
      end: isRtl ? null : 0,
      width: gutterWidth,
      child: SafeArea(
        left: isRtl,
        right: !isRtl,
        top: false,
        bottom: false,
        minimum: EdgeInsets.zero,
        child: Align(
          alignment: isRtl
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: scrollbarWidth,
            child: ReciterAlphabetScrollbar(
              key: const ValueKey('alphabet_scrollbar'),
              allReciters: reciters,
              scrollController: scrollController,
              onLetterSelected: onLetterSelected,
              scrollbarSemanticsLabel: scrollbarSemanticsLabel,
              scrollbarSemanticsHint: scrollbarSemanticsHint,
            ),
          ),
        ),
      ),
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
      return _RecitersLoadingSection();
    }

    if (state is RecitersError) {
      return _RecitersErrorSliver(
        failureMessage:
            (state as RecitersError).failure.localizedMessage(context) ??
            context.l10n.unexpectedError,
        onRetry: onRetry,
      );
    }

    if (state is RecitersLoaded) {
      final RecitersLoaded loadedState = state as RecitersLoaded;

      if (!allowHeavyLoadedResults) {
        return _RecitersLoadingSection();
      }

      if (loadedState.filteredReciters.isEmpty) {
        return _RecitersEmptySliver(state: loadedState, onClearAll: onClearAll);
      }

      if (context.isNarrow) {
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

    return _RecitersLoadingSection();
  }
}

class _RecitersLoadingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DryLayoutSafeFillSliver(
      child: TilawaLoadingIndicator(
        semanticsLabel: context.l10n.loadingReciters,
      ),
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
    return _DryLayoutSafeFillSliver(
      child: _StatePanel(
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
    final bool isFavoritesOnlyEmpty =
        state.showFavoritesOnly && !isSearchState;
    final bool hasActiveFilters = _hasActiveFilters(state);

    return _DryLayoutSafeFillSliver(
      child: _StatePanel(
        key: const ValueKey('empty_state'),
        icon: isSearchState
            ? Icons.search_off_rounded
            : isFavoritesOnlyEmpty
            ? Icons.favorite_border_rounded
            : Icons.person_off_outlined,
        title: isSearchState
            ? context.l10n.noRecitersMatchSearch
            : isFavoritesOnlyEmpty
            ? context.l10n.noFavorites
            : context.l10n.noRecitersFound,
        subtitle: isSearchState ? context.l10n.tryDifferentSearch : null,
        actionLabel: hasActiveFilters ? context.l10n.clearAll : null,
        onAction: hasActiveFilters ? onClearAll : null,
        actionLeadingIcon: Icons.clear_all_rounded,
      ),
    );
  }
}

/// Reciters list chrome: title, optional filter chips, and search row.
class _RecitersTilawaAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _RecitersTilawaAppBar({
    required this.bottomHeight,
    required this.state,
    required this.letterIndexAvailable,
    required this.showLetterIndex,
    required this.searchController,
    required this.focusNode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleFavorites,
    required this.onToggleLetterIndex,
    required this.onClearFavoritesFilter,
    required this.onClearLetterFilter,
    required this.onClearAllFilters,
  });

  final double bottomHeight;
  final RecitersState state;
  final bool letterIndexAvailable;

  @override
  Size get preferredSize => Size.fromHeight(bottomHeight);
  final bool showLetterIndex;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleFavorites;
  final VoidCallback onToggleLetterIndex;
  final VoidCallback onClearFavoritesFilter;
  final VoidCallback onClearLetterFilter;
  final VoidCallback onClearAllFilters;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final RecitersLoaded? loaded =
        state is RecitersLoaded ? state as RecitersLoaded : null;

    return TilawaCatalogAppBar(
      preferredHeight: bottomHeight,
      title: context.l10n.reciters,
      bottomContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchField(
            controller: searchController,
            focusNode: focusNode,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
          SizedBox(height: tokens.spaceSmall),
          _RecitersQuickFilterBar(
            state: state,
            loaded: loaded,
            letterIndexAvailable: letterIndexAvailable,
            showLetterIndex: showLetterIndex,
            onToggleFavorites: onToggleFavorites,
            onToggleLetterIndex: onToggleLetterIndex,
            onClearLetterFilter: onClearLetterFilter,
            onClearAllFilters: onClearAllFilters,
          ),
        ],
      ),
    );
  }
}

/// Booking-style quick filters under search (favorites, A–Z, downloads).
class _RecitersQuickFilterBar extends StatelessWidget {
  const _RecitersQuickFilterBar({
    required this.state,
    required this.loaded,
    required this.letterIndexAvailable,
    required this.showLetterIndex,
    required this.onToggleFavorites,
    required this.onToggleLetterIndex,
    required this.onClearLetterFilter,
    required this.onClearAllFilters,
  });

  final RecitersState state;
  final RecitersLoaded? loaded;
  final bool letterIndexAvailable;
  final bool showLetterIndex;
  final VoidCallback onToggleFavorites;
  final VoidCallback onToggleLetterIndex;
  final VoidCallback onClearLetterFilter;
  final VoidCallback onClearAllFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = Theme.of(context).tokens;
    final bool favoritesReady = context.select<FavoritesCubit, bool>(
      (c) => c.state is FavoritesLoaded,
    );
    final int favoriteCount = context.select<FavoritesCubit, int>((cubit) {
      final FavoritesState favoritesState = cubit.state;
      return favoritesState is FavoritesLoaded
          ? favoritesState.favoriteIds.length
          : 0;
    });
    final bool favoritesSelected =
        loaded?.showFavoritesOnly ?? false;
    final String? selectedLetter = loaded?.selectedLetter;
    final RecitersLoaded? loadedState = loaded;
    final bool showClearAll =
        loadedState != null && _showHeaderClearAll(loadedState);

    final bool showFavoritesCountOnly =
        !favoritesSelected && favoriteCount > 0;
    final String favoritesLabel = favoritesSelected || favoriteCount == 0
        ? l10n.recitersFilterChipFavorites
        : favoriteCount.toString();
    final IconData favoritesIcon = favoritesSelected
        ? Icons.favorite_rounded
        : Icons.favorite_border_rounded;

    TilawaSelectionPill catalogFilterPill({
      required String label,
      required bool selected,
      required VoidCallback? onTap,
      IconData? icon,
      bool showLabel = true,
    }) {
      return TilawaSelectionPill(
        label: label,
        icon: icon,
        selected: selected,
        onTap: onTap,
        showLabel: showLabel,
        style: TilawaSelectionPillStyle.catalog,
        elevatedWhenSelected: false,
      );
    }

    final List<Widget> pills = <Widget>[
      TourTarget(
        targetId: RecitersTourTargets.favoritesToggle,
        child: Semantics(
          identifier: ReciterSemanticsIds.recitersFavoritesToggle,
          label: showFavoritesCountOnly
              ? l10n.recitersFilterPillFavoritesCount(favoriteCount)
              : null,
          child: catalogFilterPill(
            label: favoritesLabel,
            icon: favoritesIcon,
            selected: favoritesSelected,
            onTap: favoritesReady ? onToggleFavorites : null,
          ),
        ),
      ),
      if (letterIndexAvailable)
        Semantics(
          identifier: ReciterSemanticsIds.recitersLetterIndexToggle,
          child: catalogFilterPill(
            label: l10n.recitersFilterPillAlphabet,
            icon: Icons.sort_by_alpha_rounded,
            selected: showLetterIndex,
            onTap: onToggleLetterIndex,
          ),
        ),
      if (selectedLetter != null && !showLetterIndex)
        catalogFilterPill(
          label: l10n.recitersFilterChipLetter(selectedLetter),
          selected: true,
          onTap: onClearLetterFilter,
        ),
      const _RecitersFilterNavigationDivider(),
      Semantics(
        identifier: ReciterSemanticsIds.recitersViewDownloads,
        label: l10n.viewDownloads,
        button: true,
        child: Tooltip(
          message: l10n.viewDownloads,
          child: catalogFilterPill(
            label: l10n.viewDownloads,
            icon: Icons.file_download_outlined,
            selected: false,
            showLabel: false,
            onTap: () => const DownloadsRoute().push(context),
          ),
        ),
      ),
    ];

    return TilawaQuickFilterBar(
      trailing: showClearAll
          ? TextButton(
              onPressed: onClearAllFilters,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
                minimumSize: Size(0, tokens.minInteractiveDimension),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.clearAll),
            )
          : null,
      children: pills,
    );
  }
}

/// Separates stateful catalog filters from the downloads navigation control.
class _RecitersFilterNavigationDivider extends StatelessWidget {
  const _RecitersFilterNavigationDivider();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceTiny),
      child: SizedBox(
        height: tokens.iconSizeMedium,
        child: VerticalDivider(
          width: tokens.spaceTiny,
          thickness: tokens.borderWidthThin,
          color: colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _RecitersAmbientBackground extends StatelessWidget {
  const _RecitersAmbientBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExcludeSemantics(
      child: CustomPaint(
        painter: _RecitersAmbientPainter(
          colorScheme: theme.colorScheme,
          tokens: theme.tokens,
        ),
      ),
    );
  }
}

class _RecitersAmbientPainter extends CustomPainter {
  const _RecitersAmbientPainter({
    required this.colorScheme,
    required this.tokens,
  });

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Paint wash = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.2),
        radius: 1.4,
        colors: <Color>[
          colorScheme.primary.withValues(alpha: tokens.opacitySubtle * 0.18),
          Colors.transparent,
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, wash);
  }

  @override
  bool shouldRepaint(_RecitersAmbientPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.tokens != tokens;
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
    return TourTarget(
      targetId: RecitersTourTargets.searchField,
      child: Semantics(
        identifier: ReciterSemanticsIds.recitersSearchField,
        child: TilawaSearchField(
          controller: controller,
          focusNode: focusNode,
          hintText: context.l10n.searchReciters,
          prefixIcon: FluentIcons.search_24_regular,
          clearIcon: FluentIcons.dismiss_24_regular,
          onChanged: onChanged,
          onClear: onClear,
          clearButtonTooltip: context.l10n.a11yClearRecitersSearch,
          showShadow: false,
          onTapOutside: (_) => focusNode.unfocus(),
        ),
      ),
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
    this.isError = false,
    this.actionLeadingIcon,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;
  final IconData? actionLeadingIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = isError
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return TilawaIllustratedState(
      icon: icon,
      iconColor: accent,
      title: title,
      subtitle: subtitle,
      semanticLabel: title,
      primaryAction: actionLabel != null && onAction != null
          ? TilawaButton(
              text: actionLabel!,
              variant: isError
                  ? TilawaButtonVariant.secondary
                  : TilawaButtonVariant.primary,
              leadingIcon: actionLeadingIcon != null
                  ? Icon(actionLeadingIcon)
                  : isError
                  ? const Icon(Icons.refresh_rounded)
                  : null,
              onPressed: onAction,
            )
          : null,
    );
  }
}

class _DryLayoutSafeFillSliver extends StatelessWidget {
  const _DryLayoutSafeFillSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final double height = math.max(
          constraints.remainingPaintExtent,
          0,
        );

        return SliverToBoxAdapter(
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: constraints.crossAxisExtent,
              height: height,
            ),
            child: child,
          ),
        );
      },
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
          sliver: SliverMainAxisGroup(
            slivers: [
              _RecitersResultSummarySliver(count: reciterCount),
              SliverList.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index.isOdd) {
                    return SizedBox(height: tokens.spaceSmall);
                  }

                  final ReciterEntity reciter =
                      state.filteredReciters[index ~/ 2];
                  final Widget card = ReciterCard(
                    key: ValueKey(reciter.id),
                    reciter: reciter,
                    favoritesOnlyContext: state.showFavoritesOnly,
                  );
                  if (index == 0) {
                    return TourTarget(
                      targetId: RecitersTourTargets.firstReciterCard,
                      child: card,
                    );
                  }
                  return card;
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecitersResultSummarySliver extends StatelessWidget {
  const _RecitersResultSummarySliver({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(bottom: tokens.spaceSmall),
        child: Text(
          context.l10n.recitersResultCount(count),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
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
        tokens.narrowCardWidthThreshold +
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
          sliver: SliverMainAxisGroup(
            slivers: [
              _RecitersResultSummarySliver(
                count: state.filteredReciters.length,
              ),
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: targetItemExtent,
                  mainAxisExtent: targetItemHeight,
                  mainAxisSpacing: tokens.spaceSmall + tokens.spaceTiny,
                  crossAxisSpacing: tokens.spaceSmall + tokens.spaceTiny,
                ),
                itemCount: state.filteredReciters.length,
                itemBuilder: (context, index) {
                  final ReciterEntity reciter = state.filteredReciters[index];
                  return ReciterCard(
                    key: ValueKey(reciter.id),
                    reciter: reciter,
                    favoritesOnlyContext: state.showFavoritesOnly,
                  );
                },
              ),
            ],
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
    this.scrollbarSemanticsLabel,
    this.scrollbarSemanticsHint,
  });
  final List<ReciterEntity> allReciters;
  final ScrollController scrollController;
  final Function(String? letter) onLetterSelected;

  /// Group label for the scrollbar (e.g. letter index).
  final String? scrollbarSemanticsLabel;

  /// Hint describing drag-to-jump behavior.
  final String? scrollbarSemanticsHint;

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

    return TilawaAlphabetScrollbar(
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
      scrollbarSemanticsLabel: widget.scrollbarSemanticsLabel,
      scrollbarSemanticsHint: widget.scrollbarSemanticsHint,
    );
  }
}

/// Reserved width for the letter-index rail (scrollbar + outer margin).
double _recitersLetterIndexGutterWidth(ThemeData theme) {
  final tokens = theme.tokens;
  return theme.componentTokens.alphabetScrollbar.width + tokens.spaceMedium;
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
      ? _recitersLetterIndexGutterWidth(theme)
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

int _structuralFilterCount(RecitersLoaded state) {
  return <bool>[
    state.showFavoritesOnly,
    state.selectedLetter != null,
  ].where((bool active) => active).length;
}

/// Header [Clear all] when more than one constraint is active.
bool _showHeaderClearAll(RecitersLoaded state) {
  final int structural = _structuralFilterCount(state);
  if (structural > 1) {
    return true;
  }
  return structural >= 1 && state.searchQuery.isNotEmpty;
}
