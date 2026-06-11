import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:tilawa/features/downloads/presentation/widgets/downloads_screen_scope.dart';
import 'package:tilawa/features/reciters/presentation/scroll/reciters_alphabet_scrub_coordinator.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_card.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciters_catalog_search_field.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciters_favorites_tab.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
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
import '../bloc/reciters_tabs_bloc.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../reciter_semantics_ids.dart';
import '../tour/reciters_tour_launcher.dart';
import '../tour/reciters_tour_targets.dart';
import '../utils/reciters_loaded_rebuild_policy.dart';

/// Main-shell system back: collapse expanded player, focus the reciters tab,
/// then exit — all handled explicitly.
///
/// [canPop] is pinned to `false` so system back is *always* delivered to
/// [PopScope.onPopInvokedWithResult], where the decision is made fresh at press
/// time. Two reasons this is explicit rather than driven by `canPop`:
///
///  * The shell sits at the root of a nested navigator whose root route cannot
///    be popped, so `canPop: true` does **not** exit the app here — exit must
///    be done explicitly via [SystemNavigator.pop].
///  * A dynamic `canPop` is a cached value the framework only re-reads on
///    rebuild. Returning from the full-screen Quran reader (a root route over
///    the shell) raced with the route stack settling and froze `canPop` at
///    `false`, making back a dead no-op until an unrelated tab switch. Reading
///    state fresh in the callback removes that timing dependency entirely.
class RecitersRootBackScope extends StatelessWidget {
  const RecitersRootBackScope({super.key, required this.child});

  final Widget child;

  /// Pure exit policy, kept static so it stays unit-testable without a tree.
  /// Only the reciters tab (index 0), sitting on the main shell, may exit.
  static bool canExitApp(int mainTabIndex) {
    if (mainTabIndex != 0) {
      return false;
    }
    return QuranPlayerRoutePolicy.isMainShell(
      QuranPlayerRoutePolicy.currentMatchedLocation(),
    );
  }

  /// Whether a system-back press would exit the app — the policy the
  /// [onPopInvokedWithResult] callback applies. Back never exits while the
  /// expanded player is intercepting it, otherwise it follows [canExitApp].
  /// [PopScope.canPop] is pinned to `false` (we exit explicitly in the
  /// callback), so this stays a pure, test-only description of that decision.
  static bool canPop(int mainTabIndex) {
    if (QuranPlayerSystemBackCoordinator.interceptsSystemBack) {
      return false;
    }
    return canExitApp(mainTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        // Expanded player intercepts back to collapse the now-playing sheet.
        if (QuranPlayerSystemBackCoordinator.interceptsSystemBack) {
          QuranPlayerSystemBackCoordinator.handleSystemBack();
          return;
        }
        final int tabIndex = context.read<MainScreenCubit>().state.currentIndex;
        if (tabIndex != 0) {
          context.read<MainScreenCubit>().selectTab(0);
          return;
        }
        // Reciters tab: this scope is the active back handler only on the main
        // shell ('/'); pushed routes handle their own back. So a back here
        // means "exit the app".
        SystemNavigator.pop();
      },
      child: child,
    );
  }
}

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _initialRecitersLoadDelay = Duration(
    milliseconds: 1500,
  );
  static const Duration _startupLiteUiDuration = Duration(milliseconds: 650);
  static const Duration _loadedResultsActivationDelay = Duration(
    milliseconds: 500,
  );

  final ScrollController _allScrollController = ScrollController();
  final ScrollController _favoritesScrollController = ScrollController();
  final GlobalKey<NestedScrollViewState> _nestedScrollViewKey =
      GlobalKey<NestedScrollViewState>();
  final ValueNotifier<bool> _alphabetScrubbingNotifier = ValueNotifier<bool>(
    false,
  );
  late final RecitersAlphabetScrubCoordinator _alphabetScrub;
  Timer? _initialLoadTimer;
  Timer? _loadedResultsActivationTimer;
  Timer? _startupLiteUiTimer;
  bool _isStartupLiteUi = true;
  bool _allowHeavyLoadedResults = false;
  bool _introTourAttempted = false;
  late final FavoritesCubit _favoritesCubit;
  late final TabController _tabController;

  ScrollController get _activeRecitersScrollController =>
      context.read<RecitersTabsBloc>().state.selectedTab ==
          RecitersHomeTab.favorites
      ? _favoritesScrollController
      : _allScrollController;

  @override
  void initState() {
    super.initState();
    _alphabetScrub = RecitersAlphabetScrubCoordinator(
      innerController: () => _nestedScrollViewKey.currentState?.innerController,
      primaryController: () {
        if (!mounted) {
          return null;
        }
        return PrimaryScrollController.maybeOf(context);
      },
    );
    _favoritesCubit = getIt<FavoritesCubit>();
    final RecitersBloc recitersBloc = context.read<RecitersBloc>();
    final RecitersTabsBloc tabsBloc = context.read<RecitersTabsBloc>();
    final RecitersState startupState = recitersBloc.state;
    final RecitersHomeTab initialTab = tabsBloc.state.selectedTab;
    _tabController = TabController(
      length: RecitersHomeTab.values.length,
      vsync: this,
      initialIndex: initialTab.index,
    )..addListener(_onHomeTabChanged);

    if (startupState is RecitersLoaded) {
      _isStartupLiteUi = false;
      _allowHeavyLoadedResults = true;
      _ensureFavoritesLoaded();
      _scheduleRecitersIntroTour();
      return;
    }

    if (startupState is RecitersLoading) {
      _isStartupLiteUi = false;
      _ensureFavoritesLoaded();
      return;
    }

    if (_startupReadinessPreparedReciters()) {
      _isStartupLiteUi = false;
      _allowHeavyLoadedResults = true;
      _ensureFavoritesLoaded();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || recitersBloc.state is! RecitersInitial) {
          return;
        }
        recitersBloc.add(const LoadReciters());
      });
      return;
    }

    _startupLiteUiTimer = Timer(_startupLiteUiDuration, () {
      if (!mounted) return;
      setState(() {
        _isStartupLiteUi = false;
      });
      _ensureFavoritesLoaded();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoadTimer = Timer(_initialRecitersLoadDelay, () {
        if (!mounted) return;
        recitersBloc.add(const LoadReciters());
      });
    });
  }

  /// Skips the repository round-trip when [FavoritesCubit] was seeded from
  /// the splash-prefetched cache — otherwise the favorites filter chip and
  /// per-card heart icons would briefly flicker through [FavoritesLoading].
  void _ensureFavoritesLoaded() {
    if (_favoritesCubit.state is FavoritesLoaded) {
      return;
    }
    _favoritesCubit.loadFavorites();
  }

  bool _startupReadinessPreparedReciters() {
    if (!getIt.isRegistered<AppStartupReadiness>()) {
      return false;
    }
    final readiness = getIt<AppStartupReadiness>();
    return readiness.shellPrepComplete && readiness.recitersDataReady;
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
        unawaited(
          getIt<RecitersTourLauncher>().maybeShowRecitersIntro(context),
        );
      });
    });
  }

  @override
  void dispose() {
    _alphabetScrubbingNotifier.dispose();
    _startupLiteUiTimer?.cancel();
    _loadedResultsActivationTimer?.cancel();
    _initialLoadTimer?.cancel();
    _tabController.dispose();
    _allScrollController.dispose();
    _favoritesScrollController.dispose();
    _favoritesCubit.close();
    super.dispose();
  }

  void _scrollPrimaryToTop() {
    final ScrollController? primaryScrollController =
        PrimaryScrollController.maybeOf(context);
    final ScrollController fallback = _activeRecitersScrollController;
    final ScrollController scrollController =
        primaryScrollController != null && primaryScrollController.hasClients
        ? primaryScrollController
        : fallback;
    if (!scrollController.hasClients) {
      return;
    }

    _animateScrollControllerTo(
      scrollController,
      0,
      duration: context.tokens.durationFast,
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollInnerCatalogToTop() {
    final NestedScrollViewState? nestedScrollViewState =
        _nestedScrollViewKey.currentState;
    final ScrollController? innerController =
        nestedScrollViewState?.innerController;
    if (innerController == null || !innerController.hasClients) {
      _scrollPrimaryToTop();
      return;
    }

    _alphabetScrub.clampNestedScrollOverscroll();
    _alphabetScrub.scrollInnerCatalogToTopPreservingHeader();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _alphabetScrub.restoreNonCatalogScrubScrollLocks();
    });
  }

  void _schedulePinnedScrollEnforcement({int pass = 0}) {
    if (!_alphabetScrub.alphabetScrubbingActive || pass >= 3) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_alphabetScrub.alphabetScrubbingActive) {
        return;
      }
      _alphabetScrub.enforcePinnedScrollLocks();
      _schedulePinnedScrollEnforcement(pass: pass + 1);
    });
  }

  void _scheduleScrubOverscrollClamp() {
    if (_alphabetScrub.scrubOverscrollClampScheduled ||
        !_alphabetScrub.alphabetScrubbingActive) {
      return;
    }
    _alphabetScrub.scrubOverscrollClampScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alphabetScrub.scrubOverscrollClampScheduled = false;
      if (!mounted || !_alphabetScrub.alphabetScrubbingActive) {
        return;
      }
      _alphabetScrub.clampNestedScrollOverscroll();
      _alphabetScrub.enforcePinnedScrollLocks();
    });
  }

  bool _handleNestedScrollNotification(ScrollNotification notification) {
    final bool needsEnforcement = _alphabetScrub.handleNestedScrollNotification(
      notification,
    );

    if (!_alphabetScrub.alphabetScrubbingActive) {
      return false;
    }

    if (notification.metrics.pixels < 0) {
      _scheduleScrubOverscrollClamp();
      return false;
    }

    if (needsEnforcement) {
      _schedulePinnedScrollEnforcement();
    }

    return false;
  }

  void _scrollToTop() => _scrollPrimaryToTop();

  void _onAlphabetScrubStart() {
    _alphabetScrub.alphabetScrubbingActive = true;
    _alphabetScrubbingNotifier.value = true;
    context.read<AlphabetScrollbarBloc>().add(const StartDragging());
    _alphabetScrub.beginScrub();
    _scheduleScrubOverscrollClamp();
    setState(() {});
  }

  void _onAlphabetScrubEnd() {
    _alphabetScrub.clampNestedScrollOverscroll();
    _scrollInnerCatalogToTop();
    _alphabetScrub.clearLockState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _alphabetScrub.clampNestedScrollOverscroll();
      _alphabetScrubbingNotifier.value = false;
      if (_alphabetScrub.alphabetScrubbingActive) {
        setState(() => _alphabetScrub.alphabetScrubbingActive = false);
      }
    });
  }

  void _onHomeTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    _selectHomeTabIndex(_tabController.index);
  }

  void _selectHomeTab(RecitersHomeTab tab) {
    _selectHomeTabIndex(tab.index);
  }

  void _selectHomeTabIndex(int index) {
    context.read<RecitersTabsBloc>().add(
      RecitersTabSelected(RecitersHomeTab.values[index]),
    );
  }

  void _syncRecitersFilterForTab(RecitersHomeTab selectedTab) {
    if (selectedTab == RecitersHomeTab.favorites) {
      return;
    }

    final RecitersState recitersState = context.read<RecitersBloc>().state;
    if (recitersState is! RecitersLoaded || !recitersState.showFavoritesOnly) {
      return;
    }

    context.read<RecitersBloc>().add(const ClearFavoritesFilter());
  }

  void _syncTabController(RecitersHomeTab selectedTab) {
    if (_tabController.index == selectedTab.index) {
      return;
    }
    _tabController.animateTo(selectedTab.index);
  }

  void _onLetterSelected(String? letter) {
    if (letter == null || letter.isEmpty) {
      _clearLetterFilter();
      return;
    }

    context.read<RecitersBloc>().add(FilterByLetter(letter));
    if (_alphabetScrub.alphabetScrubbingActive ||
        context.read<AlphabetScrollbarBloc>().state.isDragging) {
      _schedulePinnedScrollEnforcement();
      return;
    }
    _scrollInnerCatalogToTop();
  }

  void _clearLetterFilter() {
    context.read<RecitersBloc>().add(const ClearLetterFilter());
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
  }

  void _clearAllFilters() {
    context.read<RecitersBloc>().add(const ClearLetterFilter());
    context.read<RecitersBloc>().add(const ClearFavoritesFilter());
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
    _selectHomeTab(RecitersHomeTab.all);
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
            BlocListener<MainScreenCubit, MainScreenState>(
              listenWhen: (previous, current) =>
                  previous.recitersSearchFocusTick !=
                  current.recitersSearchFocusTick,
              listener: (context, state) {
                const RecitersSearchRoute().push(context);
              },
            ),
            BlocListener<RecitersTabsBloc, RecitersTabsState>(
              listenWhen: (previous, current) =>
                  previous.selectedTab != current.selectedTab,
              listener: (context, state) {
                _syncTabController(state.selectedTab);
                _syncRecitersFilterForTab(state.selectedTab);
              },
            ),
            BlocListener<LocalizationBloc, LocalizationState>(
              listener: (context, state) {
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
                _syncRecitersFilterForTab(
                  context.read<RecitersTabsBloc>().state.selectedTab,
                );
              },
            ),
            BlocListener<FavoritesCubit, FavoritesState>(
              listenWhen: (_, current) => current is FavoritesLoaded,
              listener: (context, state) {
                if (state is FavoritesLoaded) {
                  context.read<RecitersBloc>().add(
                    SyncFavoriteIds(state.favoriteIds),
                  );
                }
              },
            ),
            BlocListener<SettingsCubit, SettingsState>(
              listenWhen: (previous, current) =>
                  previous.showRecitersAlphabetIndex &&
                  !current.showRecitersAlphabetIndex,
              listener: (context, state) {
                _clearLetterFilter();
              },
            ),
          ],
          child: BlocBuilder<RecitersBloc, RecitersState>(
            buildWhen: (previous, current) {
              if (previous is RecitersLoaded && current is RecitersLoaded) {
                return shouldRebuildRecitersLoaded(previous, current);
              }
              return true;
            },
            builder: (context, state) {
              final bool showLetterIndex = context.select<SettingsCubit, bool>(
                (cubit) => cubit.state.showRecitersAlphabetIndex,
              );
              final headerChrome = _RecitersHeaderChrome(
                tabController: _tabController,
                onOpenSearch: () => const RecitersSearchRoute().push(context),
                onTabSelected: _selectHomeTabIndex,
              );

              return ValueListenableBuilder<bool>(
                valueListenable: _alphabetScrubbingNotifier,
                builder: (context, notifierScrubbing, _) {
                  final bool alphabetScrubbing =
                      notifierScrubbing ||
                      _alphabetScrub.alphabetScrubbingActive ||
                      context.select<AlphabetScrollbarBloc, bool>(
                        (bloc) => bloc.state.isDragging,
                      );

                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    appBar: TilawaCatalogAppBar.titleOnly(
                      context,
                      title: context.l10n.reciters,
                    ),
                    body: SafeArea(
                      bottom: false,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _handleNestedScrollNotification,
                        child: NestedScrollView(
                          key: _nestedScrollViewKey,
                          physics: alphabetScrubbing
                              ? const NeverScrollableScrollPhysics()
                              : null,
                          headerSliverBuilder: (context, innerBoxIsScrolled) {
                            return [
                              _RecitersScrollingHeaderSliver(
                                title: context.l10n.reciters,
                                headerChrome: headerChrome,
                              ),
                              SliverOverlapAbsorber(
                                handle:
                                    NestedScrollView.sliverOverlapAbsorberHandleFor(
                                      context,
                                    ),
                                sliver: _RecitersPinnedTabBarSliver(
                                  headerChrome: headerChrome,
                                ),
                              ),
                            ];
                          },
                          body: _RecitersTabbedBody(
                            tabController: _tabController,
                            state: state,
                            allowHeavyLoadedResults: _allowHeavyLoadedResults,
                            showLetterIndex: showLetterIndex,
                            allScrollController: _allScrollController,
                            favoritesScrollController:
                                _favoritesScrollController,
                            onClearAll: _clearAllFilters,
                            alphabetScrubbing: alphabetScrubbing,
                            onLetterSelected: _onLetterSelected,
                            onAlphabetScrubStart: _onAlphabetScrubStart,
                            onAlphabetScrubEnd: _onAlphabetScrubEnd,
                            onRetry: _refreshReciters,
                            onBrowseReciters: () =>
                                _selectHomeTab(RecitersHomeTab.all),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
    required this.pageStorageKey,
    required this.state,
    required this.allowHeavyLoadedResults,
    required this.showLetterIndex,
    required this.scrollController,
    required this.onClearAll,
    required this.alphabetScrubbing,
    required this.onLetterSelected,
    required this.onAlphabetScrubStart,
    required this.onAlphabetScrubEnd,
    required this.onRetry,
  });

  final PageStorageKey<String> pageStorageKey;
  final RecitersState state;
  final bool allowHeavyLoadedResults;
  final bool showLetterIndex;
  final ScrollController scrollController;
  final VoidCallback onClearAll;
  final bool alphabetScrubbing;
  final ValueChanged<String?> onLetterSelected;
  final VoidCallback onAlphabetScrubStart;
  final VoidCallback onAlphabetScrubEnd;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('_RecitersSliverScreen');
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final tokens = Theme.of(context).tokens;
    final double letterIndexTopInset =
        _recitersPinnedTabBarHeight(context) + tokens.spaceSmall;
    final double letterIndexBottomInset = tokens.spaceSmall;
    final bool letterIndexAvailable = switch (state) {
      RecitersLoaded loaded when allowHeavyLoadedResults =>
        loaded.filteredReciters.isNotEmpty,
      _ => false,
    };
    final bool showLetterIndexRail = letterIndexAvailable && showLetterIndex;
    final ScrollController? primaryScrollController =
        PrimaryScrollController.maybeOf(context);

    final Widget catalogScrollView = CustomScrollView(
      key: pageStorageKey,
      controller: primaryScrollController == null ? scrollController : null,
      physics: alphabetScrubbing
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        _RecitersResultSection(
          state: state,
          allowHeavyLoadedResults: allowHeavyLoadedResults,
          reserveScrollbarSpace: showLetterIndexRail,
          reserveScrollbarOnLeading: isRtl,
          onClearAll: onClearAll,
          onRetry: onRetry,
        ),
      ],
    );

    final Widget catalogLayer = alphabetScrubbing
        ? NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (OverscrollIndicatorNotification notification) {
              notification.disallowIndicator();
              return true;
            },
            child: catalogScrollView,
          )
        : NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (OverscrollIndicatorNotification notification) {
              return false;
            },
            child: RefreshIndicator.adaptive(
              onRefresh: onRetry,
              notificationPredicate: defaultScrollNotificationPredicate,
              child: catalogScrollView,
            ),
          );

    return MediaQuery(
      data: MediaQuery.of(context).removeViewInsets(removeBottom: true),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _RecitersAmbientBackground()),
          catalogLayer,
          if (alphabetScrubbing)
            const Positioned.fill(
              child: AbsorbPointer(child: SizedBox.expand()),
            ),
          if (showLetterIndexRail)
            _RecitersLetterIndexGutter(
              isRtl: isRtl,
              topInset: letterIndexTopInset,
              bottomInset: letterIndexBottomInset,
              reciters: (state as RecitersLoaded).reciters,
              onLetterSelected: onLetterSelected,
              onScrubStart: onAlphabetScrubStart,
              onScrubEnd: onAlphabetScrubEnd,
              scrollbarSemanticsLabel: context.l10n.a11yRecitersLetterIndex,
              scrollbarSemanticsHint:
                  context.l10n.a11yRecitersAlphabetScrollbarHint,
            ),
        ],
      ),
    );
  }
}

class _RecitersTabbedBody extends StatelessWidget {
  const _RecitersTabbedBody({
    required this.tabController,
    required this.state,
    required this.allowHeavyLoadedResults,
    required this.showLetterIndex,
    required this.allScrollController,
    required this.favoritesScrollController,
    required this.onClearAll,
    required this.onLetterSelected,
    required this.alphabetScrubbing,
    required this.onAlphabetScrubStart,
    required this.onAlphabetScrubEnd,
    required this.onRetry,
    required this.onBrowseReciters,
  });

  final TabController tabController;
  final RecitersState state;
  final bool allowHeavyLoadedResults;
  final bool showLetterIndex;
  final ScrollController allScrollController;
  final ScrollController favoritesScrollController;
  final VoidCallback onClearAll;
  final ValueChanged<String?> onLetterSelected;
  final bool alphabetScrubbing;
  final VoidCallback onAlphabetScrubStart;
  final VoidCallback onAlphabetScrubEnd;
  final Future<void> Function() onRetry;
  final VoidCallback onBrowseReciters;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        _RecitersKeepAliveTab(
          child: _RecitersSliverScreen(
            pageStorageKey: const PageStorageKey<String>('reciters_all_tab'),
            state: state,
            allowHeavyLoadedResults: allowHeavyLoadedResults,
            showLetterIndex: showLetterIndex,
            scrollController: allScrollController,
            onClearAll: onClearAll,
            alphabetScrubbing: alphabetScrubbing,
            onLetterSelected: onLetterSelected,
            onAlphabetScrubStart: onAlphabetScrubStart,
            onAlphabetScrubEnd: onAlphabetScrubEnd,
            onRetry: onRetry,
          ),
        ),
        _RecitersKeepAliveTab(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: _RecitersAmbientBackground()),
              RecitersFavoritesTab(
                pageStorageKey: const PageStorageKey<String>(
                  'reciters_favorites_tab',
                ),
                scrollController: favoritesScrollController,
              ),
            ],
          ),
        ),
        _RecitersKeepAliveTab(
          child: _RecitersDownloadsTab(onBrowseReciters: onBrowseReciters),
        ),
      ],
    );
  }
}

/// Keeps off-screen [TabBarView] pages mounted to avoid rebuild jank on swipes.
class _RecitersKeepAliveTab extends StatefulWidget {
  const _RecitersKeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_RecitersKeepAliveTab> createState() => _RecitersKeepAliveTabState();
}

class _RecitersKeepAliveTabState extends State<_RecitersKeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _RecitersDownloadsTab extends StatelessWidget {
  const _RecitersDownloadsTab({required this.onBrowseReciters});

  final VoidCallback onBrowseReciters;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: _RecitersAmbientBackground()),
        DownloadsScreenScope(
          child: DownloadsNestedTabView(onBrowseReciters: onBrowseReciters),
        ),
      ],
    );
  }
}

/// Letter-index rail pinned to the trailing screen edge (Pinterest-style).
class _RecitersLetterIndexGutter extends StatelessWidget {
  const _RecitersLetterIndexGutter({
    required this.isRtl,
    required this.topInset,
    required this.bottomInset,
    required this.reciters,
    required this.onLetterSelected,
    required this.onScrubStart,
    required this.onScrubEnd,
    required this.scrollbarSemanticsLabel,
    required this.scrollbarSemanticsHint,
  });

  final bool isRtl;
  final double topInset;
  final double bottomInset;
  final List<ReciterEntity> reciters;
  final ValueChanged<String?> onLetterSelected;
  final VoidCallback onScrubStart;
  final VoidCallback onScrubEnd;
  final String? scrollbarSemanticsLabel;
  final String? scrollbarSemanticsHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double gutterWidth = _recitersLetterIndexGutterWidth(theme);
    final double scrollbarWidth = theme.componentTokens.alphabetScrollbar.width;

    return PositionedDirectional(
      top: topInset,
      bottom: bottomInset,
      start: isRtl ? 0 : null,
      end: isRtl ? null : 0,
      width: gutterWidth,
      child: Listener(
        behavior: HitTestBehavior.opaque,
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
                onLetterSelected: onLetterSelected,
                onScrubStart: onScrubStart,
                onScrubEnd: onScrubEnd,
                scrollbarSemanticsLabel: scrollbarSemanticsLabel,
                scrollbarSemanticsHint: scrollbarSemanticsHint,
              ),
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
        return _RecitersEmptySliver(
          state: loadedState,
          onClearAll: onClearAll,
        );
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
  const _RecitersEmptySliver({
    required this.state,
    required this.onClearAll,
  });

  final RecitersLoaded state;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return _DryLayoutSafeFillSliver(
      contentAlignment: _recitersEmptyContentAlignment(context),
      child: _RecitersEmptyStateContent(
        key: const ValueKey('empty_state'),
        state: state,
        onClearAll: onClearAll,
      ),
    );
  }
}

/// Empty catalog / filter messaging with calm, contextual actions.
class _RecitersEmptyStateContent extends StatelessWidget {
  const _RecitersEmptyStateContent({
    super.key,
    required this.state,
    required this.onClearAll,
  });

  final RecitersLoaded state;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final bool showClearAll = _hasActiveFilters(state);
    final String title = context.l10n.noRecitersFound;
    final IconData icon = Icons.person_off_outlined;

    final Widget? primaryAction = showClearAll
        ? TilawaButton(
            text: context.l10n.clearAll,
            variant: TilawaButtonVariant.outline,
            leadingIcon: Icon(
              Icons.clear_all_rounded,
              size: tokens.iconSizeSmall,
            ),
            onPressed: onClearAll,
          )
        : null;

    return TilawaIllustratedState(
      icon: icon,
      title: title,
      semanticLabel: title,
      maxWidth: tokens.contentMaxWidthForm * 0.6,
      primaryAction: primaryAction,
    );
  }
}

Alignment _recitersEmptyContentAlignment(BuildContext context) {
  return const Alignment(0, -0.2);
}

double _recitersPinnedTabBarHeight(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final TilawaDesignTokens tokens = theme.tokens;
  final EdgeInsets padding = TilawaAppBarConfig.catalogChromePadding(tokens);

  return padding.vertical + kTextTabBarHeight;
}

class _RecitersHeaderChrome {
  const _RecitersHeaderChrome({
    required this.tabController,
    required this.onOpenSearch,
    required this.onTabSelected,
  });

  final TabController tabController;
  final VoidCallback onOpenSearch;
  final ValueChanged<int> onTabSelected;
}

class _RecitersScrollingHeaderSliver extends StatelessWidget {
  const _RecitersScrollingHeaderSliver({
    required this.title,
    required this.headerChrome,
  });

  final String title;
  final _RecitersHeaderChrome headerChrome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;

    return SliverToBoxAdapter(
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: TilawaAppBarConfig.catalogChromePadding(tokens).copyWith(
            bottom: 0,
          ),
          child: TourTarget(
            targetId: RecitersTourTargets.searchField,
            child: RecitersCatalogSearchField.launcher(
              semanticsIdentifier: ReciterSemanticsIds.recitersSearchLauncher,
              onTap: headerChrome.onOpenSearch,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecitersPinnedTabBarSliver extends StatelessWidget {
  const _RecitersPinnedTabBarSliver({
    required this.headerChrome,
  });

  final _RecitersHeaderChrome headerChrome;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _RecitersPinnedTabBarDelegate(
        height: _recitersPinnedTabBarHeight(context),
        headerChrome: headerChrome,
      ),
    );
  }
}

class _RecitersPinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _RecitersPinnedTabBarDelegate({
    required this.height,
    required this.headerChrome,
  });

  final double height;
  final _RecitersHeaderChrome headerChrome;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _RecitersPinnedTabBarContent(headerChrome: headerChrome);
  }

  @override
  bool shouldRebuild(_RecitersPinnedTabBarDelegate oldDelegate) {
    return height != oldDelegate.height ||
        headerChrome != oldDelegate.headerChrome;
  }
}

class _RecitersPinnedTabBarContent extends StatelessWidget {
  const _RecitersPinnedTabBarContent({required this.headerChrome});

  final _RecitersHeaderChrome headerChrome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;

    return Material(
      color: theme.colorScheme.surface,
      shape: TilawaAppBarChrome.bottomHairline(theme.colorScheme, tokens),
      child: TilawaSearchFieldSlot(
        padding: TilawaAppBarConfig.catalogChromePadding(tokens),
        child: _RecitersHomeTabBar(
          controller: headerChrome.tabController,
          onTabSelected: headerChrome.onTabSelected,
        ),
      ),
    );
  }
}

class _RecitersHomeTabBar extends StatelessWidget {
  const _RecitersHomeTabBar({
    required this.controller,
    required this.onTabSelected,
  });

  final TabController controller;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final chipTokens = theme.componentTokens.chip;
    final int favoriteCount = context.select<FavoritesCubit, int>((cubit) {
      final FavoritesState favoritesState = cubit.state;
      return favoritesState is FavoritesLoaded
          ? favoritesState.favoriteIds.length
          : 0;
    });

    return Row(
      spacing: tokens.spaceSmall,
      children: [
        Expanded(
          child: SizedBox(
            height: kTextTabBarHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
              ),
              child: TabBar(
                controller: controller,
                onTap: onTabSelected,
                splashBorderRadius: BorderRadius.circular(
                  tokens.radiusExtraLarge,
                ),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.all(tokens.spaceExtraSmall),
                indicator: BoxDecoration(
                  color: chipTokens.catalogSelectedBackgroundColor,
                  borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
                ),
                labelColor: chipTokens.catalogSelectedForegroundColor,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: chipTokens.selectionFontWeight,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  _RecitersTab(
                    label: context.l10n.reciters,
                    identifier: ReciterSemanticsIds.recitersTab,
                  ),
                  _RecitersTab(
                    label: favoriteCount > 0
                        ? context.l10n.recitersFilterPillFavoritesCount(
                            favoriteCount,
                          )
                        : context.l10n.recitersFilterChipFavorites,
                    identifier: ReciterSemanticsIds.recitersFavoritesToggle,
                    tourTargetId: RecitersTourTargets.favoritesToggle,
                  ),
                  _RecitersTab(
                    label: context.l10n.downloads,
                    identifier: ReciterSemanticsIds.recitersViewDownloads,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecitersTab extends StatelessWidget {
  const _RecitersTab({
    required this.label,
    required this.identifier,
    this.tourTargetId,
  });

  final String label;
  final String identifier;
  final String? tourTargetId;

  @override
  Widget build(BuildContext context) {
    Widget labelWidget = Semantics(
      identifier: identifier,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (tourTargetId != null) {
      labelWidget = TourTarget(targetId: tourTargetId!, child: labelWidget);
    }

    return Tab(
      height: kTextTabBarHeight,
      child: labelWidget,
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

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    super.key,
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  }) : subtitle = null,
       actionLeadingIcon = null;

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
  const _DryLayoutSafeFillSliver({
    required this.child,
    this.contentAlignment = Alignment.center,
  });

  final Widget child;
  final Alignment contentAlignment;

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
            child: Align(
              alignment: contentAlignment,
              child: child,
            ),
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
    final bool showResultSummary = _shouldShowRecitersResultSummary(state);

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

        final int itemCount = reciterCount + reciterCount - 1;

        return SliverPadding(
          padding: padding,
          sliver: SliverMainAxisGroup(
            slivers: [
              if (showResultSummary)
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

bool _shouldShowRecitersResultSummary(RecitersLoaded state) {
  return state.selectedLetter != null;
}

class _RecitersResultSummarySliver extends StatelessWidget {
  const _RecitersResultSummarySliver({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final String summary = context.l10n.recitersResultCount(count);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(bottom: tokens.spaceSmall),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
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

        final bool showResultSummary = _shouldShowRecitersResultSummary(state);

        return SliverPadding(
          padding: padding,
          sliver: SliverMainAxisGroup(
            slivers: [
              if (showResultSummary)
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
    required this.onLetterSelected,
    required this.onScrubStart,
    required this.onScrubEnd,
    this.scrollbarSemanticsLabel,
    this.scrollbarSemanticsHint,
  });
  final List<ReciterEntity> allReciters;
  final ValueChanged<String?> onLetterSelected;
  final VoidCallback onScrubStart;
  final VoidCallback onScrubEnd;

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
    widget.onLetterSelected(letter);
  }

  @override
  Widget build(BuildContext context) {
    if (_letters.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedLetter = switch (context.watch<RecitersBloc>().state) {
      RecitersLoaded(:final selectedLetter) => selectedLetter,
      _ => null,
    };

    return TilawaAlphabetScrollbar(
      letters: _letters,
      selectedLetter: selectedLetter,
      onLetterSelected: _handleLetterSelection,
      onPanStart: (_) {
        widget.onScrubStart();
      },
      onPanUpdate: (_) {},
      onPanEnd: (_) {
        context.read<AlphabetScrollbarBloc>().add(const EndDragging());
        widget.onScrubEnd();
      },
      scrollbarSemanticsLabel: widget.scrollbarSemanticsLabel,
      scrollbarSemanticsHint: widget.scrollbarSemanticsHint,
      scrollbarSemanticsIdentifier:
          ReciterSemanticsIds.recitersAlphabetScrollbar,
      overlaySemanticsIdentifier: ReciterSemanticsIds.alphabetScrollbarOverlay,
      selectedLetterStableSemanticsId:
          ReciterSemanticsIds.recitersAlphabetLetterSelected,
      selectedLetterSemanticsId: ReciterSemanticsIds.alphabetLetterSelected,
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
    tokens.spaceSmall,
    ((constraints.crossAxisExtent - tokens.contentMaxWidthMedia) / 2) +
        tokens.spaceSmall,
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
  return state.selectedLetter != null;
}

void _animateScrollControllerTo(
  ScrollController controller,
  double offset, {
  required Duration duration,
  required Curve curve,
}) {
  if (!controller.hasClients) {
    return;
  }
  for (final ScrollPosition position in controller.positions) {
    position.animateTo(
      offset.clamp(0.0, position.maxScrollExtent),
      duration: duration,
      curve: curve,
    );
  }
}
