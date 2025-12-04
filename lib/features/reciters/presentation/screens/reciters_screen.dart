import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    // Load reciters asynchronously to avoid blocking UI
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
        // When language changes, refetch reciters with new language
        context.read<RecitersBloc>().add(const LanguageChanged());
      },
      child: BlocBuilder<RecitersBloc, RecitersState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.reciters),
              actions: const [LanguageSwitcher(), SizedBox(width: 8)],
            ),
            body: Column(
              children: [
                // Search bar and letter filter
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Letter filter indicator
                      if (state is RecitersLoaded &&
                          state.selectedLetter != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.filteredByLetter,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                state.selectedLetter!,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _clearLetterFilter,
                                color: Theme.of(context).primaryColor,
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                      // Search field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchReciters,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              (state is RecitersLoaded &&
                                  state.searchQuery.isNotEmpty)
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
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
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.loadingReciters,
                                    ),
                                  ],
                                ),
                              )
                            : state is RecitersError
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      size: 64,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(state.message),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.read<RecitersBloc>().add(
                                          const LoadReciters(),
                                        );
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.retry,
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
                                    const Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.searchQuery.isEmpty
                                          ? AppLocalizations.of(
                                              context,
                                            )!.noRecitersFound
                                          : AppLocalizations.of(
                                              context,
                                            )!.noRecitersMatchSearch,
                                    ),
                                  ],
                                ),
                              )
                            : state is RecitersLoaded
                            ? ListView.separated(
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                controller: _scrollController,
                                itemCount: state.filteredReciters.length,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
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
