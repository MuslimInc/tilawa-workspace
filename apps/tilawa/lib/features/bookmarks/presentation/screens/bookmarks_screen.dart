import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/features/bookmarks/presentation/widgets/bookmark_card.dart';
import 'package:tilawa_core/entities/audio.dart';

import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../shared/widgets/bottom_player_widget.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../domain/entities/bookmark_entity.dart';
import '../bloc/bookmarks_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';
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
      appBar: AppBar(
        leading: context.canPop() ? const TilawaBackButton() : null,
        title: Text(context.l10n.bookmarks),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BookmarksBloc>().add(const LoadBookmarksEvent());
            },
          ),
        ],
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
            return Stack(
              children: [
                state.when(
                  initial: () =>
                      const Center(child: CircularProgressIndicator()),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (bookmarks, filteredBookmarks, searchQuery) => Column(
                    children: [
                      BookmarkSearchBar(
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
                      Expanded(
                        child: filteredBookmarks.isEmpty
                            ? _buildEmptyState(context, searchQuery.isNotEmpty)
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
                                itemCount: filteredBookmarks.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final BookmarkEntity bookmark =
                                      filteredBookmarks[index];
                                  return Dismissible(
                                    key: ValueKey(bookmark.id),
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onDismissed: (direction) {
                                      context.read<BookmarksBloc>().add(
                                        DeleteBookmarkEvent(id: bookmark.id),
                                      );
                                    },
                                    child: BookmarkCard(
                                      bookmark: bookmark,
                                      onTap: () =>
                                          _playFromBookmark(context, bookmark),
                                      onEdit: () => _showEditLabelDialog(
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
                  bookmarkCreated: (_, bookmarks) =>
                      _buildLoadedList(context, bookmarks),
                  bookmarkUpdated: (_, bookmarks) =>
                      _buildLoadedList(context, bookmarks),
                  bookmarkDeleted: (_, bookmarks) =>
                      _buildLoadedList(context, bookmarks),
                  error: (message) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        SizedBox(height: 16),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<BookmarksBloc>().add(
                              const LoadBookmarksEvent(),
                            );
                          },
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned.fill(child: BottomPlayerWidget()),
              ],
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
        return Dismissible(
          key: ValueKey(bookmark.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            context.read<BookmarksBloc>().add(
              DeleteBookmarkEvent(id: bookmark.id),
            );
          },
          child: BookmarkCard(
            bookmark: bookmark,
            onTap: () => _playFromBookmark(context, bookmark),
            onEdit: () => _showEditLabelDialog(context, bookmark),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.bookmark_24_regular,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            isSearching
                ? context.l10n.noBookmarksFound
                : context.l10n.noBookmarks,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 8),
          Text(
            isSearching
                ? context.l10n.tryDifferentSearch
                : context.l10n.noBookmarksHint,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<BookmarksBloc>().add(
                UpdateBookmarkLabelEvent(
                  id: bookmark.id,
                  label: controller.text.isEmpty ? null : controller.text,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }
}
