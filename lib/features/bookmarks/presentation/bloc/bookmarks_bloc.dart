import 'package:dartz_plus/dartz_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/bookmark_entity.dart';
import '../../domain/usecases/usecases.dart';

part 'bookmarks_bloc.freezed.dart';
part 'bookmarks_event.dart';
part 'bookmarks_state.dart';

@injectable
class BookmarksBloc extends Bloc<BookmarksEvent, BookmarksState> {
  BookmarksBloc({
    required GetAllBookmarksUseCase getAllBookmarksUseCase,
    required CreateBookmarkUseCase createBookmarkUseCase,
    required DeleteBookmarkUseCase deleteBookmarkUseCase,
    required UpdateBookmarkLabelUseCase updateBookmarkLabelUseCase,
    required SearchBookmarksUseCase searchBookmarksUseCase,
  }) : _getAllBookmarksUseCase = getAllBookmarksUseCase,
       _createBookmarkUseCase = createBookmarkUseCase,
       _deleteBookmarkUseCase = deleteBookmarkUseCase,
       _updateBookmarkLabelUseCase = updateBookmarkLabelUseCase,
       _searchBookmarksUseCase = searchBookmarksUseCase,
       super(const BookmarksState.initial()) {
    on<LoadBookmarksEvent>(_onLoadBookmarks);
    on<CreateBookmarkEvent>(_onCreateBookmark);
    on<DeleteBookmarkEvent>(_onDeleteBookmark);
    on<UpdateBookmarkLabelEvent>(_onUpdateBookmarkLabel);
    on<SearchBookmarksEvent>(_onSearchBookmarks);
    on<ClearBookmarksSearchEvent>(_onClearSearch);
  }

  final GetAllBookmarksUseCase _getAllBookmarksUseCase;
  final CreateBookmarkUseCase _createBookmarkUseCase;
  final DeleteBookmarkUseCase _deleteBookmarkUseCase;
  final UpdateBookmarkLabelUseCase _updateBookmarkLabelUseCase;
  final SearchBookmarksUseCase _searchBookmarksUseCase;

  Future<void> _onLoadBookmarks(
    LoadBookmarksEvent event,
    Emitter<BookmarksState> emit,
  ) async {
    emit(const BookmarksState.loading());

    final Either<Failure, List<BookmarkEntity>> result =
        await _getAllBookmarksUseCase();

    result.fold(
      (failure) => emit(
        BookmarksState.error(failure.message ?? 'Failed to load bookmarks'),
      ),
      (bookmarks) => emit(
        BookmarksState.loaded(
          bookmarks: bookmarks,
          filteredBookmarks: bookmarks,
        ),
      ),
    );
  }

  Future<void> _onCreateBookmark(
    CreateBookmarkEvent event,
    Emitter<BookmarksState> emit,
  ) async {
    final Either<Failure, BookmarkEntity> result = await _createBookmarkUseCase(
      surahId: event.surahId,
      surahName: event.surahName,
      surahNameEn: event.surahNameEn,
      reciterId: event.reciterId,
      reciterName: event.reciterName,
      moshafId: event.moshafId,
      moshafName: event.moshafName,
      positionMs: event.positionMs,
      durationMs: event.durationMs,
      audioUrl: event.audioUrl,
      label: event.label,
      artworkUrl: event.artworkUrl,
    );

    await result.fold(
      (failure) async => emit(
        BookmarksState.error(failure.message ?? 'Failed to create bookmark'),
      ),
      (bookmark) async {
        // Reload bookmarks
        final Either<Failure, List<BookmarkEntity>> loadResult =
            await _getAllBookmarksUseCase();
        loadResult.fold(
          (failure) => emit(
            BookmarksState.error(failure.message ?? 'Failed to load bookmarks'),
          ),
          (bookmarks) => emit(
            BookmarksState.bookmarkCreated(
              bookmark: bookmark,
              bookmarks: bookmarks,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDeleteBookmark(
    DeleteBookmarkEvent event,
    Emitter<BookmarksState> emit,
  ) async {
    final Either<Failure, void> result = await _deleteBookmarkUseCase(event.id);

    await result.fold(
      (failure) async => emit(
        BookmarksState.error(failure.message ?? 'Failed to delete bookmark'),
      ),
      (_) async {
        // Reload bookmarks
        final Either<Failure, List<BookmarkEntity>> loadResult =
            await _getAllBookmarksUseCase();
        loadResult.fold(
          (failure) => emit(
            BookmarksState.error(failure.message ?? 'Failed to load bookmarks'),
          ),
          (bookmarks) => emit(
            BookmarksState.bookmarkDeleted(
              deletedId: event.id,
              bookmarks: bookmarks,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onUpdateBookmarkLabel(
    UpdateBookmarkLabelEvent event,
    Emitter<BookmarksState> emit,
  ) async {
    final Either<Failure, BookmarkEntity> result =
        await _updateBookmarkLabelUseCase(id: event.id, label: event.label);

    await result.fold(
      (failure) async => emit(
        BookmarksState.error(failure.message ?? 'Failed to update bookmark'),
      ),
      (bookmark) async {
        // Reload bookmarks
        final Either<Failure, List<BookmarkEntity>> loadResult =
            await _getAllBookmarksUseCase();
        loadResult.fold(
          (failure) => emit(
            BookmarksState.error(failure.message ?? 'Failed to load bookmarks'),
          ),
          (bookmarks) => emit(
            BookmarksState.bookmarkUpdated(
              bookmark: bookmark,
              bookmarks: bookmarks,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSearchBookmarks(
    SearchBookmarksEvent event,
    Emitter<BookmarksState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const LoadBookmarksEvent());
      return;
    }

    final Either<Failure, List<BookmarkEntity>> result =
        await _searchBookmarksUseCase(event.query);

    result.fold(
      (failure) => emit(
        BookmarksState.error(failure.message ?? 'Failed to search bookmarks'),
      ),
      (filteredBookmarks) {
        state.maybeWhen(
          loaded: (bookmarks, _, _) => emit(
            BookmarksState.loaded(
              bookmarks: bookmarks,
              filteredBookmarks: filteredBookmarks,
              searchQuery: event.query,
            ),
          ),
          orElse: () => emit(
            BookmarksState.loaded(
              bookmarks: filteredBookmarks,
              filteredBookmarks: filteredBookmarks,
              searchQuery: event.query,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onClearSearch(
    ClearBookmarksSearchEvent event,
    Emitter<BookmarksState> emit,
  ) async {
    add(const LoadBookmarksEvent());
  }
}
