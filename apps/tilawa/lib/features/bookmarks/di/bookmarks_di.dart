import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/bookmarks/data/datasources/bookmarks_local_datasource.dart';
import 'package:tilawa/features/bookmarks/data/repositories/bookmarks_repository_impl.dart';
import 'package:tilawa/features/bookmarks/domain/repositories/bookmarks_repository.dart';
import 'package:tilawa/features/bookmarks/domain/usecases/usecases.dart';
import 'package:tilawa/features/bookmarks/presentation/bloc/bookmarks_bloc.dart';

/// Manual GetIt registrations for `bookmarks`.
class BookmarksDi {
  BookmarksDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<BookmarksLocalDataSource>(
      () => BookmarksLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<BookmarksRepository>(
      () => BookmarksRepositoryImpl(getIt<BookmarksLocalDataSource>()),
    );
    getIt.registerLazySingletonIfAbsent<DeleteBookmarkUseCase>(
      () => DeleteBookmarkUseCase(getIt<BookmarksRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetAllBookmarksUseCase>(
      () => GetAllBookmarksUseCase(getIt<BookmarksRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SearchBookmarksUseCase>(
      () => SearchBookmarksUseCase(getIt<BookmarksRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<UpdateBookmarkLabelUseCase>(
      () => UpdateBookmarkLabelUseCase(getIt<BookmarksRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<CreateBookmarkUseCase>(
      () => CreateBookmarkUseCase(
        getIt<BookmarksRepository>(),
        getIt<AppReviewTriggerManager>(),
      ),
    );
    getIt.registerFactoryIfAbsent<BookmarksBloc>(
      () => BookmarksBloc(
        getAllBookmarksUseCase: getIt<GetAllBookmarksUseCase>(),
        createBookmarkUseCase: getIt<CreateBookmarkUseCase>(),
        deleteBookmarkUseCase: getIt<DeleteBookmarkUseCase>(),
        updateBookmarkLabelUseCase: getIt<UpdateBookmarkLabelUseCase>(),
        searchBookmarksUseCase: getIt<SearchBookmarksUseCase>(),
      ),
    );
  }
}
