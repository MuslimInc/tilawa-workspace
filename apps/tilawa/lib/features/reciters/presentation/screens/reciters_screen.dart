import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
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
              appBar: AppBar(
                title: Text(l10n.reciters),
                actions: [
                  IconButton(
                    icon: const Icon(FluentIcons.book_open_24_regular),
                    tooltip: l10n.quran,
                    onPressed: () => const QuranLastReadRoute().push(context),
                  ),
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
              body: Column(
                children: [
                  // Search bar and letter filter
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    child: Column(
                      children: [
                        // Letter filter indicator (refined)
                        if (state is RecitersLoaded &&
                            state.selectedLetter != null)
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 12.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16.r),
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
                                  size: 18.sp,
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  l10n.filteredByLetter,
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    state.selectedLetter!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _clearLetterFilter,
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: theme.primaryColor,
                                      size: 16.sp,
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
                            SizedBox(width: 10.w),
                            _FavoritesToggle(state: state),
                            SizedBox(width: 10.w),
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
                                      SizedBox(height: 16.h),
                                      Text(
                                        l10n.loadingReciters,
                                        style: TextStyle(fontSize: 14.sp),
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
                                        size: 64.sp,
                                        color: theme.colorScheme.error,
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        state.message,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      ElevatedButton(
                                        onPressed: () {
                                          context.read<RecitersBloc>().add(
                                            const LoadReciters(),
                                          );
                                        },
                                        child: Text(
                                          l10n.retry,
                                          style: TextStyle(fontSize: 14.sp),
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
                                        size: 64.sp,
                                        color: theme.disabledColor,
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        state.searchQuery.isEmpty
                                            ? l10n.noRecitersFound
                                            : l10n.noRecitersMatchSearch,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: theme.disabledColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : state is RecitersLoaded
                              ? ResponsiveBuilder(
                                  xs: (context) => _ReciterListView(
                                    state: state,
                                    scrollController: _scrollController,
                                  ),
                                  sm: (context) => _ReciterGridView(
                                    state: state,
                                    scrollController: _scrollController,
                                    crossAxisCount: 2,
                                  ),
                                  lg: (context) => _ReciterGridView(
                                    state: state,
                                    scrollController: _scrollController,
                                    crossAxisCount: 3,
                                  ),
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
          height: 54.r,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
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
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
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
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  FluentIcons.search_24_regular,
                  size: 20.sp,
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
                        icon: Icon(FluentIcons.dismiss_24_regular, size: 18.sp),
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
      height: 54.r,
      width: 54.r,
      decoration: BoxDecoration(
        color: isActive ? theme.primaryColor : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
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
          borderRadius: BorderRadius.circular(16.r),
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
              size: 22.sp,
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
      height: 54.r,
      width: 54.r,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
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
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => const DownloadsRoute().push(context),
          child: Center(
            child: Icon(
              FluentIcons.arrow_download_24_regular,
              color: theme.primaryColor,
              size: 24.sp,
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
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      controller: scrollController,
      itemCount: state.filteredReciters.length,
      padding: EdgeInsets.only(left: 8.w, right: 8.w, top: 8.h, bottom: 80.h),
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
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 8.h, bottom: 80.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        mainAxisExtent: 120.r,
      ),
      itemCount: state.filteredReciters.length,
      itemBuilder: (context, index) {
        final ReciterEntity reciter = state.filteredReciters[index];
        return ReciterCard(reciter: reciter);
      },
    );
  }
}
