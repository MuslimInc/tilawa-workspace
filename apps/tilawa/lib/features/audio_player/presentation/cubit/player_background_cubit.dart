import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../../domain/entities/player_background_configuration.dart';
import '../../domain/usecases/decode_persisted_player_background_use_case.dart';
import '../../domain/usecases/delete_player_background_use_case.dart';
import '../../domain/usecases/encode_player_background_configuration_use_case.dart';
import '../../domain/usecases/pick_player_background_use_case.dart';
import '../../domain/usecases/reset_player_background_use_case.dart';
import 'player_background_state.dart';

@injectable
class PlayerBackgroundCubit extends HydratedCubit<PlayerBackgroundState> {
  PlayerBackgroundCubit(
    this._decodePersistedConfiguration,
    this._encodeConfiguration,
    this._pickUseCase,
    this._resetUseCase,
    this._deleteUseCase,
  ) : super(const PlayerBackgroundInitial(PlayerBackgroundConfiguration()));

  final DecodePersistedPlayerBackgroundUseCase _decodePersistedConfiguration;
  final EncodePlayerBackgroundConfigurationUseCase _encodeConfiguration;
  final PickPlayerBackgroundUseCase _pickUseCase;
  final ResetPlayerBackgroundUseCase _resetUseCase;
  final DeletePlayerBackgroundUseCase _deleteUseCase;

  @override
  PlayerBackgroundState? fromJson(Map<String, dynamic> json) {
    try {
      final config = _decodePersistedConfiguration(json);
      return PlayerBackgroundInitial(config);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(PlayerBackgroundState state) {
    return _encodeConfiguration(state.config);
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      emit(PlayerBackgroundLoading(state.config));

      final result = await _pickUseCase(source);

      String? persistentPath;
      Failure? failure;
      result.fold((f) => failure = f, (p) => persistentPath = p);

      if (failure != null) {
        if (failure is UserCancelledFailure) {
          emit(PlayerBackgroundInitial(state.config));
        } else {
          emit(PlayerBackgroundError(state.config, failure!));
        }
        return;
      }

      // Clean up old image if exists
      if (state.config.customImagePath != null) {
        await _deleteUseCase(state.config.customImagePath!);
      }

      final newConfig = state.config.copyWith(
        type: PlayerBackgroundType.custom,
        customImagePath: persistentPath,
      );

      emit(PlayerBackgroundSuccess(newConfig));
    } catch (e) {
      emit(
        PlayerBackgroundError(state.config, UnexpectedFailure(e.toString())),
      );
    }
  }

  Future<void> resetToDefault() async {
    final result = await _resetUseCase(state.config.customImagePath);

    result.fold(
      (failure) => emit(PlayerBackgroundError(state.config, failure)),
      (_) =>
          emit(const PlayerBackgroundInitial(PlayerBackgroundConfiguration())),
    );
  }
}
