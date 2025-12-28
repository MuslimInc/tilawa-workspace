import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:tilawa/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/playlists/presentation/bloc/playlists_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/reciter_details_loader_cubit.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';

@GenerateMocks([
  AuthBloc,
  AudioPlayerBloc,
  DownloadsBloc,
  ReciterDetailsLoaderCubit,
  SettingsCubit,
  LocalizationBloc,
  AlphabetScrollbarBloc,
  GoRouterState,
  ReciterDetailsBloc,
  ReciterDownloadBloc,
  PlaylistsBloc,
])
void main() {}
