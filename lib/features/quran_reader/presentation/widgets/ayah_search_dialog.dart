import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions.dart';
import '../../domain/entities/ayah_entity.dart';
import '../../domain/entities/surah_content_entity.dart';
import '../bloc/quran_reader_bloc.dart';

class AyahSearchDialog extends StatefulWidget {
  const AyahSearchDialog({super.key});

  @override
  State<AyahSearchDialog> createState() => _AyahSearchDialogState();
}

class _AyahSearchDialogState extends State<AyahSearchDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(context.l10n.searchAyahs, style: theme.textTheme.titleLarge),

            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.l10n.searchAyahsHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<QuranReaderBloc>().add(
                      const QuranReaderEvent.clearSearch(),
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (query) {
                context.read<QuranReaderBloc>().add(
                  QuranReaderEvent.searchAyahs(query),
                );
              },
            ),

            const SizedBox(height: 16),

            // Search results
            Expanded(
              child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
                builder: (context, state) {
                  if (state.isSearching) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.searchResults.isEmpty &&
                      state.surahSearchResults.isEmpty) {
                    return Center(
                      child: Text(
                        state.searchQuery.isEmpty
                            ? context.l10n.enterSearchQuery
                            : context.l10n.noSearchResults,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final int totalItems =
                      (state.surahSearchResults.isNotEmpty
                          ? state.surahSearchResults.length + 1
                          : 0) +
                      (state.searchResults.isNotEmpty
                          ? state.searchResults.length + 1
                          : 0);

                  return ListView.builder(
                    itemCount: totalItems,
                    itemBuilder: (context, index) {
                      // Surah Section
                      if (state.surahSearchResults.isNotEmpty) {
                        if (index == 0) {
                          return _buildSectionHeader(context, 'Surahs');
                        }
                        if (index <= state.surahSearchResults.length) {
                          final SurahContentEntity surah =
                              state.surahSearchResults[index - 1];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                '${surah.number}',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(surah.nameEnglish),
                            subtitle: Text(surah.name),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<QuranReaderBloc>().add(
                                QuranReaderEvent.loadSurah(surah.number),
                              );
                            },
                          );
                        }
                      }

                      // Ayah Section
                      final int ayahStartIndex =
                          state.surahSearchResults.isNotEmpty
                          ? state.surahSearchResults.length + 1
                          : 0;

                      final int relativeIndex = index - ayahStartIndex;

                      if (relativeIndex == 0) {
                        return _buildSectionHeader(context, 'Ayahs');
                      }

                      final AyahEntity ayah =
                          state.searchResults[relativeIndex - 1];
                      return ListTile(
                        title: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            ayah.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Amiri'),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surah ${ayah.surahNumber}, Ayah ${ayah.numberInSurah}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (ayah.translation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  ayah.translation!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // jumpToPage handles loading the page and navigating to it
                          if (ayah.page != null) {
                            context.read<QuranReaderBloc>().add(
                              QuranReaderEvent.jumpToPage(ayah.page!),
                            );
                          }
                          // Optional: we can still send scrollToAyah for future implementation
                          context.read<QuranReaderBloc>().add(
                            QuranReaderEvent.scrollToAyah(ayah.numberInSurah),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
