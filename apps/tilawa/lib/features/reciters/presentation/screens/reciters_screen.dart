import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../../shared/widgets/arabic_alphabet_scrollbar.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import '../bloc/reciters_bloc.dart';
import '../cubit/favorites_cubit.dart';
import '../widgets/reciter_card.dart';

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
              floatingActionButtonLocation:
                  Directionality.of(context) == TextDirection.rtl
                  ? FloatingActionButtonLocation.endFloat
                  : FloatingActionButtonLocation.startFloat,
              floatingActionButton: FloatingActionButton(
                heroTag: 'reciters_fab',
                onPressed: () async {
                  await const FavoritesRoute().push(context);
                  if (context.mounted) {
                    await context.read<FavoritesCubit>().loadFavorites();
                  }
                },
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.favorite_rounded),
              ),
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
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 54.h,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Focus(
                                  onFocusChange: (hasFocus) {
                                    setState(() {});
                                  },
                                  child: Center(
                                    child: TextField(
                                      focusNode: _focusNode,
                                      controller: _searchController,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        hintText: l10n.searchReciters,
                                        hintStyle: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.4),
                                          fontSize: 14.sp,
                                        ),
                                        prefixIcon: Icon(
                                          FluentIcons.search_24_regular,
                                          size: 20.sp,
                                          color: _focusNode.hasFocus
                                              ? theme.primaryColor
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.6),
                                        ),
                                        suffixIcon:
                                            (state is RecitersLoaded &&
                                                state.searchQuery.isNotEmpty)
                                            ? IconButton(
                                                icon: Icon(
                                                  FluentIcons
                                                      .dismiss_24_regular,
                                                  size: 18.sp,
                                                ),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  context
                                                      .read<RecitersBloc>()
                                                      .add(const ClearSearch());
                                                  context
                                                      .read<
                                                        AlphabetScrollbarBloc
                                                      >()
                                                      .add(
                                                        const ClearSelection(),
                                                      );
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        context.read<RecitersBloc>().add(
                                          SearchRecitersEvent(value),
                                        );
                                      },
                                      onTapOutside: (event) {
                                        _focusNode.unfocus();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Container(
                              height: 54.h,
                              width: 54.h,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16.r),
                                  onTap: () =>
                                      const DownloadsRoute().push(context),
                                  child: Center(
                                    child: Icon(
                                      FluentIcons.arrow_download_24_regular,
                                      color: theme.primaryColor,
                                      size: 24.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
                              ? ListView.separated(
                                  separatorBuilder: (_, _) =>
                                      SizedBox(height: 8.h),
                                  controller: _scrollController,
                                  itemCount: state.filteredReciters.length,
                                  padding: EdgeInsets.only(
                                    left: 8.w,
                                    right: 8.w,
                                    top: 8.h,
                                    bottom: 80.h,
                                  ),
                                  itemBuilder: (context, index) {
                                    final ReciterEntity reciter =
                                        state.filteredReciters[index];
                                    return ReciterCard(reciter: reciter);
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
