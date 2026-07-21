import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    final tokens = theme.tokens;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(context.l10n.searchAyahs, style: theme.textTheme.titleLarge),

            SizedBox(height: tokens.spaceLarge),

            // Search field
            TilawaSearchField(
              controller: _searchController,
              hintText: context.l10n.searchAyahsHint,
              textInputAction: TextInputAction.search,
              clearButtonTooltip: context.l10n.a11yClearSearch,
              showShadow: false,
              onClear: () {
                _searchController.clear();
                context.read<QuranReaderBloc>().add(
                  const QuranReaderEvent.clearSearch(),
                );
              },
              onSubmitted: (query) {
                context.read<QuranReaderBloc>().add(
                  QuranReaderEvent.searchAyahs(query),
                );
              },
            ),

            SizedBox(height: tokens.spaceLarge),

            // Search results
            Expanded(
              child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
                builder: (context, state) {
                  if (state.isSearching) {
                    return const TilawaLoadingIndicator();
                  }

                  if (state.searchResults.isEmpty) {
                    return TilawaEmptyState(
                      icon: state.searchQuery.isEmpty
                          ? Icons.search_rounded
                          : Icons.search_off_rounded,
                      title: state.searchQuery.isEmpty
                          ? context.l10n.enterSearchQuery
                          : context.l10n.noSearchResults,
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
                          ),
                        ),
                        subtitle: Text(
                          context.l10n.surahAyahLabel(
                            ayah.surahNumber,
                            ayah.numberInSurah,
                          ),
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

            SizedBox(height: tokens.spaceLarge),

            // Close button
            TilawaButton(
              text: context.l10n.close,
              variant: TilawaButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
