import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/layout/list_scroll_bottom_padding.dart';
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
    final double keyboardInset = context.keyboardInset;

    return TilawaShellChildScaffold(
      appBar: TilawaCatalogAppBar(
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
          scrollPadding: EdgeInsets.only(bottom: keyboardInset + 24),
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
                TilawaFeedback.showToast(
                  context,
                  message: context.l10n.bookmarkAdded,
                  variant: TilawaFeedbackVariant.success,
                );
              },
              bookmarkUpdated: (_, _) {
                TilawaFeedback.showToast(
                  context,
                  message: context.l10n.bookmarkUpdated,
                  variant: TilawaFeedbackVariant.success,
                );
              },
              error: (message) {
                TilawaFeedback.showToast(
                  context,
                  message: message,
                  variant: TilawaFeedbackVariant.error,
                );
              },
            );
          },
          builder: (context, state) {
            return state.when(
              initial: () => const _BookmarksLoadingBody(),
              loading: () => const _BookmarksLoadingBody(),
              loaded: (bookmarks, filteredBookmarks, searchQuery) =>
                  _BookmarksList(
                    bookmarks: filteredBookmarks,
                    isSearching: searchQuery.isNotEmpty,
                  ),
              bookmarkCreated: (_, bookmarks) => _BookmarksList(
                bookmarks: bookmarks,
                isSearching: false,
              ),
              bookmarkUpdated: (_, bookmarks) => _BookmarksList(
                bookmarks: bookmarks,
                isSearching: false,
              ),
              bookmarkDeleted: (_, bookmarks) => _BookmarksList(
                bookmarks: bookmarks,
                isSearching: false,
              ),
              error: (message) => _BookmarksErrorState(message: message),
            );
          },
        ),
      ),
    );
  }
}

double _bookmarksScrollBottomPadding(BuildContext context) {
  if (context.isKeyboardVisible) {
    // [TilawaAdaptiveShell] hides the mini player when the keyboard is open.
    return Theme.of(context).tokens.spaceSmall;
  }
  return listScrollBottomPadding(context);
}

class _BookmarksLoadingBody extends StatelessWidget {
  const _BookmarksLoadingBody();

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: const TilawaLoadingIndicator(),
      ),
    );
  }
}

class _BookmarksList extends StatelessWidget {
  const _BookmarksList({
    required this.bookmarks,
    required this.isSearching,
  });

  final List<BookmarkEntity> bookmarks;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final double bottomPadding = _bookmarksScrollBottomPadding(context);

    if (bookmarks.isEmpty) {
      return CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: tokens.spaceLarge),
                child: _BookmarksEmptyState(isSearching: isSearching),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: bottomPadding),
          ),
        ],
      );
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLarge,
            tokens.spaceLarge,
            tokens.spaceLarge,
            tokens.spaceLarge + bottomPadding,
          ),
          sliver: SliverList.separated(
            itemCount: bookmarks.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: tokens.spaceSmall),
            itemBuilder: (context, index) {
              final BookmarkEntity bookmark = bookmarks[index];
              return Dismissible(
                key: ValueKey(bookmark.id),
                direction: DismissDirection.endToStart,
                background: const _BookmarkDismissBackground(),
                onDismissed: (_) => _onBookmarkDismissed(context, bookmark),
                child: BookmarkCard(
                  bookmark: bookmark,
                  onTap: () => _playFromBookmark(context, bookmark),
                  onEdit: () => _showEditLabelDialog(context, bookmark),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookmarksEmptyState extends StatelessWidget {
  const _BookmarksEmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return TilawaEmptyState(
      icon: Icons.bookmark_border_rounded,
      title: isSearching
          ? context.l10n.noBookmarksFound
          : context.l10n.noBookmarks,
      subtitle: isSearching
          ? context.l10n.tryDifferentSearch
          : context.l10n.noBookmarksHint,
    );
  }
}

class _BookmarksErrorState extends StatelessWidget {
  const _BookmarksErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final double bottomPadding = _bookmarksScrollBottomPadding(context);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: tokens.spaceLarge),
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
        ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: bottomPadding),
        ),
      ],
    );
  }
}

/// Delete background pinned to the reveal side in both LTR and RTL
/// (paired with `DismissDirection.endToStart`).
class _BookmarkDismissBackground extends StatelessWidget {
  const _BookmarkDismissBackground();

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
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
}

/// Deletes with an undo affordance — the recreated bookmark gets a fresh
/// id/timestamps, which is acceptable for undo semantics.
void _onBookmarkDismissed(BuildContext context, BookmarkEntity bookmark) {
  final BookmarksBloc bloc = context.read<BookmarksBloc>();
  bloc.add(DeleteBookmarkEvent(id: bookmark.id));
  TilawaFeedback.showActionable(
    context,
    message: context.l10n.bookmarkDeleted,
    variant: TilawaFeedbackVariant.success,
    dedupeKey: 'bookmark-undo-${bookmark.id}',
    actions: <TilawaFeedbackAction>[
      TilawaFeedbackAction(
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
    ],
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
      content: TilawaTextField(
        controller: controller,
        hintText: context.l10n.enterBookmarkLabel,
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
