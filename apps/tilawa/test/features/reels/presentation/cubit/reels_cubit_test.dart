import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reels/domain/entities/reel.dart';
import 'package:tilawa/features/reels/domain/usecases/get_reel_categories_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/get_reels_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/react_to_reel_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/record_reel_view_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/save_reel_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/share_reel_use_case.dart';
import 'package:tilawa/features/reels/presentation/cubit/reels_cubit.dart';
import 'package:tilawa/features/reels/presentation/cubit/reels_state.dart';

import '../../helpers/fake_reels_repository.dart';

void main() {
  late FakeReelsRepository repo;
  late ReelsCubit cubit;

  const sample = Reel(
    id: 15,
    sheikhId: 102,
    sheikhName: 'Maher',
    videoUrl: 'https://example.com/a.mp4',
    thumbUrl: 'https://example.com/a.jpg',
    categoryId: 2,
  );

  setUp(() {
    repo = FakeReelsRepository(reels: const [sample]);
    cubit = ReelsCubit(
      GetReelsUseCase(repo),
      GetReelCategoriesUseCase(repo),
      SaveReelUseCase(repo),
      RemoveSavedReelUseCase(repo),
      ReactToReelUseCase(repo),
      ShareReelUseCase(repo),
      RecordReelViewUseCase(repo),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<ReelsCubit, ReelsState>(
    'load emits ready with reels',
    build: () => cubit,
    act: (c) => c.load(
      language: 'eng',
      allLabel: 'All',
      categoryLabels: const {2: 'Prophet', 3: 'Faith', 4: 'Ramadan'},
    ),
    expect: () => [
      isA<ReelsState>().having((s) => s.status, 'status', ReelsStatus.loading),
      isA<ReelsState>()
          .having((s) => s.status, 'status', ReelsStatus.ready)
          .having((s) => s.reels.length, 'count', 1),
    ],
  );

  blocTest<ReelsCubit, ReelsState>(
    'load emits error when repository fails',
    build: () {
      repo.failGet = true;
      return cubit;
    },
    act: (c) => c.load(
      language: 'eng',
      allLabel: 'All',
      categoryLabels: const {2: 'Prophet', 3: 'Faith', 4: 'Ramadan'},
    ),
    verify: (c) {
      check(c.state.status).equals(ReelsStatus.error);
    },
  );
}
