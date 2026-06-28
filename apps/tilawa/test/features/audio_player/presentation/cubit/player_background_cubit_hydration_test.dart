import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/audio_player/domain/usecases/decode_persisted_player_background_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/delete_player_background_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/encode_player_background_configuration_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/pick_player_background_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/reset_player_background_use_case.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';

class MockDecodePersistedPlayerBackgroundUseCase extends Mock
    implements DecodePersistedPlayerBackgroundUseCase {}

class MockEncodePlayerBackgroundConfigurationUseCase extends Mock
    implements EncodePlayerBackgroundConfigurationUseCase {}

class MockPickPlayerBackgroundUseCase extends Mock
    implements PickPlayerBackgroundUseCase {}

class MockResetPlayerBackgroundUseCase extends Mock
    implements ResetPlayerBackgroundUseCase {}

class MockDeletePlayerBackgroundUseCase extends Mock
    implements DeletePlayerBackgroundUseCase {}

void main() {
  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  test('PlayerBackgroundCubit remains a HydratedCubit', () {
    final PlayerBackgroundCubit cubit = PlayerBackgroundCubit(
      MockDecodePersistedPlayerBackgroundUseCase(),
      MockEncodePlayerBackgroundConfigurationUseCase(),
      MockPickPlayerBackgroundUseCase(),
      MockResetPlayerBackgroundUseCase(),
      MockDeletePlayerBackgroundUseCase(),
    );

    expect(cubit, isA<HydratedCubit<PlayerBackgroundState>>());
    cubit.close();
  });
}
