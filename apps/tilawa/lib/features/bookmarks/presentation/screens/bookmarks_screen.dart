import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/features/bookmarks/presentation/widgets/bookmark_card.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../domain/entities/bookmark_entity.dart';
import '../bloc/bookmarks_bloc.dart';
import '../widgets/bookmark_search_bar.dart';

/// Screen for displaying and managing bookmarks.
///
/// NOTE: This screen expects a [BookmarksBloc] to be provided in the widget tree.
/// The bloc is provided by [BookmarksRoute] in the router configuration.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TilawaCatalogAppBar(
        preferredHeight: TilawaAppBarConfig.catalogTitleAndSearchHeight(
          context,
        ),
        title: context.l10n.bookmarks,
        automaticallyImplyLeading: true,
        onBackPressed: () => context.pop(),
        actions: [
          TilawaIconActionButton(
            icon: Icons.refresh,
            onTap: () {
              context.read<BookmarksBloc>().add(const LoadBookmarksEvent());
            },
          ),
        ],
        bottomContent: BookmarkSearchBar(
          onSearchChanged: (query) {
            context.read<BookmarksBloc>().add(
              SearchBookmarksEvent(query: query),
            );
          },
          onClearSearch: () {
            context.read<BookmarksBloc>().add(
              const ClearBookmarksSearchEvent(),
            );
          },
        ),
      ),
      body: TilawaContentBounds(
        kind: TilawaContentKind.media,
        child: BlocConsumer<BookmarksBloc, BookmarksState>(
          listener: (context, state) {
            state.whenOrNull(
              bookmarkCreated: (bookmark, _) {
                ToastUtils.showSuccessToast(context.l10n.bookmarkAdded);
              },
              bookmarkDeleted: (_, _) {
                ToastUtils.showSuccessToast(context.l10n.bookmarkDeleted);
              },
              bookmarkUpdated: (_, _) {
                ToastUtils.showSuccessToast(context.l10n.bookmarkUpdated);
              },
              error: (message) {
                ToastUtils.showErrorToast(message);
              },
            );
          },
          builder: (context, state) {
            return SafeArea(
              child: Stack(
                children: [
                  state.when(
                    initial: () => const TilawaLoadingIndicator(),
                    loading: () => const TilawaLoadingIndicator(),
                    loaded: (bookmarks, filteredBookmarks, searchQuery) =>
                        Positioned.fill(
                          child: CustomScrollView(
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: filteredBookmarks.isNotEmpty,
                                child: filteredBookmarks.isEmpty
                                    ? _buildEmptyState(
                                        context,
                                        searchQuery.isNotEmpty,
                                      )
                                    : ListView.separated(
                                        padding: EdgeInsets.fromLTRB(
                                          16,
                                          16,
                                          16,
                                          120,
                                        ),
                                        itemCount: filteredBookmarks.length,
                                        separatorBuilder: (context, index) =>
                                            SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final BookmarkEntity bookmark =
                                              filteredBookmarks[index];
                                          final tokens = Theme.of(
                                            context,
                                          ).tokens;
                                          return Dismissible(
                                            key: ValueKey(bookmark.id),
                                            direction:
                                                DismissDirection.endToStart,
                                            background: _dismissBackground(
                                              context,
                                              tokens,
                                            ),
                                            onDismissed: (_) =>
                                                _onBookmarkDismissed(
                                                  context,
                                                  bookmark,
                                                ),
                                            child: BookmarkCard(
                                              bookmark: bookmark,
                                              onTap: () => _playFromBookmark(
                                                context,
                                                bookmark,
                                              ),
                                              onEdit: () =>
                                                  _showEditLabelDialog(
                                                    context,
                                                    bookmark,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                    bookmarkCreated: (_, bookmarks) => Positioned.fill(
                      child: _buildLoadedList(context, bookmarks),
                    ),
                    bookmarkUpdated: (_, bookmarks) => Positioned.fill(
                      child: _buildLoadedList(context, bookmarks),
                    ),
                    bookmarkDeleted: (_, bookmarks) => Positioned.fill(
                      child: _buildLoadedList(context, bookmarks),
                    ),
                    error: (message) => Positioned.fill(
                      child: TilawaErrorState(
                        icon: Icons.error_outline_rounded,
                        title: message,
                        retryLabel: context.l10n.retry,
                        onRetry: () {
                          context.read<BookmarksBloc>().add(
                            const LoadBookmarksEvent(),
                          );
                        },
                        iconColor: Theme.of(context).colorScheme.error,
                      ),
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

  Widget _buildLoadedList(
    BuildContext context,
    List<BookmarkEntity> bookmarks,
  ) {
    if (bookmarks.isEmpty) {
      return _buildEmptyState(context, false);
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: bookmarks.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final BookmarkEntity bookmark = bookmarks[index];
        final tokens = Theme.of(context).tokens;
        return Dismissible(
          key: ValueKey(bookmark.id),
          direction: DismissDirection.endToStart,
          background: _dismissBackground(context, tokens),
          onDismissed: (_) => _onBookmarkDismissed(context, bookmark),
          child: BookmarkCard(
            bookmark: bookmark,
            onTap: () => _playFromBookmark(context, bookmark),
            onEdit: () => _showEditLabelDialog(context, bookmark),
          ),
        );
      },
    );
  }

  /// Delete background pinned to the reveal side in both LTR and RTL
  /// (paired with `DismissDirection.endToStart`).
  Widget _dismissBackground(BuildContext context, TilawaDesignTokens tokens) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsetsDirectional.only(end: tokens.spaceLarge),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.card),
        ),
      ),
      child: Icon(Icons.delete_outline_rounded, color: colorScheme.onError),
    );
  }

  /// Deletes with an undo affordance — the recreated bookmark gets a fresh
  /// id/timestamps, which is acceptable for undo semantics.
  void _onBookmarkDismissed(BuildContext context, BookmarkEntity bookmark) {
    final BookmarksBloc bloc = context.read<BookmarksBloc>();
    bloc.add(DeleteBookmarkEvent(id: bookmark.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.bookmarkDeleted),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => bloc.add(
              CreateBookmarkEvent(
                surahId: bookmark.surahId,
                surahName: bookmark.surahName,
                surahNameEn: bookmark.surahNameEn,
                reciterId: bookmark.reciterId,
                reciterName: bookmark.reciterName,
                moshafId: bookmark.moshafId,
                moshafName: bookmark.moshafName,
                positionMs: bookmark.positionMs,
                durationMs: bookmark.durationMs,
                audioUrl: bookmark.audioUrl,
                label: bookmark.label,
                artworkUrl: bookmark.artworkUrl,
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: TilawaEmptyState(
          icon: FluentIcons.bookmark_24_regular,
          title: isSearching
              ? context.l10n.noBookmarksFound
              : context.l10n.noBookmarks,
          subtitle: isSearching
              ? context.l10n.tryDifferentSearch
              : context.l10n.noBookmarksHint,
        ),
      ),
    );
  }

  void _playFromBookmark(BuildContext context, BookmarkEntity bookmark) {
    final audio = AudioEntity(
      id: bookmark.audioUrl,
      title: bookmark.surahName,
      url: bookmark.audioUrl,
      duration: bookmark.duration,
      artist: bookmark.reciterName,
      album: bookmark.moshafName,
      artUri: bookmark.artworkUrl,
      extras: {
        'surahId': bookmark.surahId,
        'reciterId': bookmark.reciterId,
        'moshafId': bookmark.moshafId,
      },
    );

    context.read<AudioPlayerBloc>().add(
      AudioPlayerEvent.playFromQueue(
        [audio],
        0,
        initialPosition: bookmark.position,
      ),
    );
  }

  void _showEditLabelDialog(BuildContext context, BookmarkEntity bookmark) {
    final controller = TextEditingController(text: bookmark.label ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.editBookmarkLabel),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.enterBookmarkLabel,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TilawaButton(
            text: context.l10n.cancel,
            variant: TilawaButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TilawaButton(
            text: context.l10n.save,
            variant: TilawaButtonVariant.primary,
            onPressed: () {
              context.read<BookmarksBloc>().add(
                UpdateBookmarkLabelEvent(
                  id: bookmark.id,
                  label: controller.text.isEmpty ? null : controller.text,
                ),
              );
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }
}
