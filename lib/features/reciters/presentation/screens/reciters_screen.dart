import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/reciter_model.dart';
import '../../../../shared/widgets/arabic_alphabet_scrollbar.dart';
import '../../../alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../bloc/reciters_bloc.dart';
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

  void _onLetterSelected(String letter) {
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
    return BlocListener<LocalizationBloc, LocalizationState>(
      listener: (context, state) {
        context.read<RecitersBloc>().add(const LanguageChanged());
      },
      child: BlocBuilder<RecitersBloc, RecitersState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.reciters)),
            body: Column(
              children: [
                // Search bar and letter filter
                Container(
                  padding: EdgeInsets.all(4.r),
                  margin: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Letter filter indicator
                      if (state is RecitersLoaded &&
                          state.selectedLetter != null)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt_rounded,
                                color: theme.primaryColor,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                l10n.filteredByLetter,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                state.selectedLetter!,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: _clearLetterFilter,
                                color: theme.primaryColor,
                                iconSize: 20.sp,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      // Search field
                      Focus(
                        onFocusChange: (hasFocus) {
                          setState(() {});
                        },
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _searchController,
                          style: TextStyle(fontSize: 14.sp),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            hintText: l10n.searchReciters,
                            prefixIcon: Icon(
                              FluentIcons.search_24_regular,
                              size: 22.sp,
                              color: _focusNode.hasFocus
                                  ? theme.primaryColor
                                  : null,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            suffixIcon:
                                (state is RecitersLoaded &&
                                    state.searchQuery.isNotEmpty)
                                ? IconButton(
                                    icon: const Icon(
                                      FluentIcons.dismiss_24_regular,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<RecitersBloc>().add(
                                        const ClearSearch(),
                                      );
                                      context.read<AlphabetScrollbarBloc>().add(
                                        const ClearSelection(),
                                      );
                                      // Keep focus or un-focus? Usually clear keeps focus if user wants to type again.
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
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                itemBuilder: (context, index) {
                                  final Reciter reciter =
                                      state.filteredReciters[index];
                                  return ReciterCard(reciter: reciter);
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      // Arabic alphabet scrollbar
                      if (state is RecitersLoaded &&
                          state.reciters.isNotEmpty &&
                          state.searchQuery.isEmpty)
                        ReciterAlphabetScrollbar(
                          reciters: state
                              .filteredReciters, // Use filtered list for scrolling
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
    );
  }
}
