import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_card.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../../shared/widgets/arabic_alphabet_scrollbar.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import '../bloc/reciters_bloc.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecitersBloc>().add(const LoadReciters());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onLetterSelected(String? letter) {
    if (letter == null || letter.isEmpty) {
      _clearLetterFilter();
      return;
    }
    context.read<RecitersBloc>().add(FilterByLetter(letter));
    _searchController.clear();
  }

  void _clearLetterFilter() {
    context.read<RecitersBloc>().add(const ClearLetterFilter());
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return MultiBlocListener(
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
            // Restore selected letter filter when reciters are loaded
            final String? selectedLetter = context
                .read<AlphabetScrollbarBloc>()
                .state
                .selectedLetter;
            if (selectedLetter != null) {
              context.read<RecitersBloc>().add(FilterByLetter(selectedLetter));
            }
          },
        ),
      ],
      child: BlocProvider(
        create: (context) => getIt<FavoritesCubit>()..loadFavorites(),
        child: BlocBuilder<RecitersBloc, RecitersState>(
          builder: (context, state) {
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
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => const QuranLastReadRoute().push(context),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 4,
                child: const Icon(Icons.menu_book_rounded),
              ),
              body: Column(
                children: [
                  // Search bar and letter filter
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        // Letter filter indicator (refined)
                        if (state is RecitersLoaded &&
                            state.selectedLetter != null)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  FluentIcons.filter_24_filled,
                                  color: theme.primaryColor,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  l10n.filteredByLetter,
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    state.selectedLetter!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _clearLetterFilter,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: theme.primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Search field
                        // Search and Filters
                        Row(
                          children: [
                            Expanded(
                              child: _SearchField(
                                state: state,
                                controller: _searchController,
                                focusNode: _focusNode,
                              ),
                            ),
                            SizedBox(width: 10),
                            _FavoritesToggle(state: state),
                            SizedBox(width: 10),
                            const _DownloadsButton(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scrollbar (Right side for RTL)
                        if (Directionality.of(context) == TextDirection.rtl &&
                            state is RecitersLoaded &&
                            state.reciters.isNotEmpty &&
                            state.searchQuery.isEmpty)
                          ReciterAlphabetScrollbar(
                            reciters: state.filteredReciters,
                            scrollController: _scrollController,
                            onLetterSelected: _onLetterSelected,
                          ),

                        // Main content
                        Expanded(
                          child: state is RecitersLoading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text(
                                        l10n.loadingReciters,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              : state is RecitersError
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 64,
                                        color: theme.colorScheme.error,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        state.message,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          context.read<RecitersBloc>().add(
                                            const LoadReciters(),
                                          );
                                        },
                                        child: Text(
                                          l10n.retry,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : state is RecitersLoaded &&
                                    state.filteredReciters.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 64,
                                        color: theme.disabledColor,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        state.searchQuery.isEmpty
                                            ? l10n.noRecitersFound
                                            : l10n.noRecitersMatchSearch,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: theme.disabledColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : state is RecitersLoaded
                              ? LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth >= 1100) {
                                      return _ReciterGridView(
                                        state: state,
                                        scrollController: _scrollController,
                                        crossAxisCount: 3,
                                      );
                                    }
                                    if (constraints.maxWidth >= 700) {
                                      return _ReciterGridView(
                                        state: state,
                                        scrollController: _scrollController,
                                        crossAxisCount: 2,
                                      );
                                    }
                                    return _ReciterListView(
                                      state: state,
                                      scrollController: _scrollController,
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Scrollbar (Right side for LTR)
                        if (Directionality.of(context) != TextDirection.rtl &&
                            state is RecitersLoaded &&
                            state.reciters.isNotEmpty &&
                            state.searchQuery.isEmpty)
                          ReciterAlphabetScrollbar(
                            reciters: state.filteredReciters,
                            scrollController: _scrollController,
                            onLetterSelected: _onLetterSelected,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.state,
    required this.controller,
    required this.focusNode,
  });

  final RecitersState state;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        return Container(
          height: 54,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: focusNode.hasFocus
                  ? theme.primaryColor.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                hintText: l10n.searchReciters,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  FluentIcons.search_24_regular,
                  size: 20,
                  color: focusNode.hasFocus
                      ? theme.primaryColor
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                ),
                suffixIcon:
                    (state is RecitersLoaded &&
                        (state as RecitersLoaded).searchQuery.isNotEmpty)
                    ? IconButton(
                        icon: Icon(FluentIcons.dismiss_24_regular, size: 18),
                        onPressed: () {
                          controller.clear();
                          context.read<RecitersBloc>().add(const ClearSearch());
                          context.read<AlphabetScrollbarBloc>().add(
                            const ClearSelection(),
                          );
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<RecitersBloc>().add(SearchRecitersEvent(value));
              },
              onTapOutside: (event) => focusNode.unfocus(),
            ),
          ),
        );
      },
    );
  }
}

class _FavoritesToggle extends StatelessWidget {
  const _FavoritesToggle({required this.state});

  final RecitersState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isActive =
        state is RecitersLoaded && (state as RecitersLoaded).showFavoritesOnly;

    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: isActive ? theme.primaryColor : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? theme.primaryColor.withValues(alpha: 0.2)
                : theme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive
              ? theme.primaryColor
              : theme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final favoritesState = context.read<FavoritesCubit>().state;
            if (favoritesState is FavoritesLoaded) {
              context.read<RecitersBloc>().add(
                ToggleFavoritesFilter(favoritesState.favoriteIds.toList()),
              );
            }
          },
          child: Center(
            child: Icon(
              isActive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isActive ? Colors.white : theme.primaryColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadsButton extends StatelessWidget {
  const _DownloadsButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => const DownloadsRoute().push(context),
          child: Center(
            child: Icon(
              FluentIcons.arrow_download_24_regular,
              color: theme.primaryColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReciterListView extends StatelessWidget {
  const _ReciterListView({required this.state, required this.scrollController});

  final RecitersLoaded state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (_, _) => SizedBox(height: 8),
      controller: scrollController,
      itemCount: state.filteredReciters.length,
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
      itemBuilder: (context, index) {
        final ReciterEntity reciter = state.filteredReciters[index];
        return ReciterCard(reciter: reciter);
      },
    );
  }
}

class _ReciterGridView extends StatelessWidget {
  const _ReciterGridView({
    required this.state,
    required this.scrollController,
    required this.crossAxisCount,
  });

  final RecitersLoaded state;
  final ScrollController scrollController;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 120,
      ),
      itemCount: state.filteredReciters.length,
      itemBuilder: (context, index) {
        final ReciterEntity reciter = state.filteredReciters[index];
        return ReciterCard(reciter: reciter);
      },
    );
  }
}
