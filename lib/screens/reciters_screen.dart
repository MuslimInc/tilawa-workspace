import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/shared/widgets/language_switcher.dart';
import 'package:muzakri/shared/widgets/arabic_alphabet_scrollbar.dart';

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
    context.read<RecitersBloc>().add(const LoadReciters());
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
    return BlocBuilder<RecitersBloc, RecitersState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.reciters),
            actions: [const LanguageSwitcher(), const SizedBox(width: 8)],
          ),
          body: Column(
            children: [
              // Search bar and letter filter
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Letter filter indicator
                    if (state is RecitersLoaded && state.selectedLetter != null)
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
                        hintText: AppLocalizations.of(context)!.searchReciters,
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                  Icon(
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
                                  Icon(
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
                          ? ListView.builder(
                              controller: _scrollController,
                              itemCount: state.filteredReciters.length,
                              itemBuilder: (context, index) {
                                final reciter = state.filteredReciters[index];
                                return _buildReciterCard(context, reciter);
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
    );
  }

  Widget _buildReciterCard(BuildContext context, Reciter reciter) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            reciter.letter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          reciter.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${reciter.moshaf.length} recitation(s) available'),
            if (reciter.moshaf.isNotEmpty)
              Text(
                reciter.moshaf.first.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.pushNamed(
            'reciterDetails',
            pathParameters: {'reciterId': reciter.id.toString()},
            extra: reciter,
          );
        },
      ),
    );
  }
}
