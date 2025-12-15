import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/reciter_model.dart';
import '../../../../shared/widgets/arabic_alphabet_scrollbar.dart';
import '../../../../shared/widgets/language_switcher.dart';
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
    return BlocListener<LocalizationBloc, LocalizationState>(
      listener: (context, state) {
        context.read<RecitersBloc>().add(const LanguageChanged());
      },
      child: BlocBuilder<RecitersBloc, RecitersState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.reciters),
            ),
            body: Column(
              children: [
                // Search bar and letter filter
                Container(
                  padding: EdgeInsets.all(4.r),
                  margin: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
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
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                AppLocalizations.of(context)!.filteredByLetter,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                state.selectedLetter!,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: _clearLetterFilter,
                                color: Theme.of(context).primaryColor,
                                iconSize: 20.sp,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      // Search field
                      TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
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
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchReciters,
                          prefixIcon: Icon(
                            FluentIcons.search_24_regular,
                            size: 22.sp,
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
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          context.read<RecitersBloc>().add(
                            SearchRecitersEvent(value),
                          );
                        },
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
                                      AppLocalizations.of(
                                        context,
                                      )!.loadingReciters,
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
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
                                        AppLocalizations.of(context)!.retry,
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
                                      color: Theme.of(context).disabledColor,
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      state.searchQuery.isEmpty
                                          ? AppLocalizations.of(
                                              context,
                                            )!.noRecitersFound
                                          : AppLocalizations.of(
                                              context,
                                            )!.noRecitersMatchSearch,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Theme.of(context).disabledColor,
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
