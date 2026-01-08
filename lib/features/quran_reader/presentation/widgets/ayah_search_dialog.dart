import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions.dart';
import '../../domain/entities/ayah_entity.dart';
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

                  if (state.searchResults.isEmpty) {
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

                  return ListView.builder(
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final AyahEntity ayah = state.searchResults[index];
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
                        subtitle: Text(
                          'Surah ${ayah.surahNumber}, Ayah ${ayah.numberInSurah}',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<QuranReaderBloc>().add(
                            QuranReaderEvent.loadSurah(ayah.surahNumber),
                          );
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
}
