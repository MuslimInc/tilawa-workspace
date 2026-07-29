import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/playlists/data/datasources/playlists_local_datasource.dart';
import 'package:tilawa/features/playlists/data/repositories/playlists_repository_impl.dart';
import 'package:tilawa/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:tilawa/features/playlists/domain/usecases/usecases.dart';
import 'package:tilawa/features/playlists/presentation/bloc/playlists_bloc.dart';

/// Manual GetIt registrations for `playlists`.
class PlaylistsDi {
  PlaylistsDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<PlaylistsLocalDataSource>(
      () => PlaylistsLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<PlaylistsRepository>(
      () => PlaylistsRepositoryImpl(getIt<PlaylistsLocalDataSource>()),
    );
    getIt.registerLazySingletonIfAbsent<AddItemToPlaylistUseCase>(
      () => AddItemToPlaylistUseCase(getIt<PlaylistsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<CreatePlaylistUseCase>(
      () => CreatePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<DeletePlaylistUseCase>(
      () => DeletePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetAllPlaylistsUseCase>(
      () => GetAllPlaylistsUseCase(getIt<PlaylistsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<RemoveItemFromPlaylistUseCase>(
      () => RemoveItemFromPlaylistUseCase(getIt<PlaylistsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SearchPlaylistsUseCase>(
      () => SearchPlaylistsUseCase(getIt<PlaylistsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ToggleFavoritePlaylistUseCase>(
      () => ToggleFavoritePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<UpdatePlaylistUseCase>(
      () => UpdatePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
    getIt.registerFactoryIfAbsent<PlaylistsBloc>(
      () => PlaylistsBloc(
        getAllPlaylistsUseCase: getIt<GetAllPlaylistsUseCase>(),
        createPlaylistUseCase: getIt<CreatePlaylistUseCase>(),
        updatePlaylistUseCase: getIt<UpdatePlaylistUseCase>(),
        deletePlaylistUseCase: getIt<DeletePlaylistUseCase>(),
        addItemToPlaylistUseCase: getIt<AddItemToPlaylistUseCase>(),
        removeItemFromPlaylistUseCase: getIt<RemoveItemFromPlaylistUseCase>(),
        searchPlaylistsUseCase: getIt<SearchPlaylistsUseCase>(),
        toggleFavoritePlaylistUseCase: getIt<ToggleFavoritePlaylistUseCase>(),
      ),
    );
  }
}
