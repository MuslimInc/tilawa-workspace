import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/compared_word.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/recitation_comparison_result.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/recitation_target.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/word_match_status.dart';
import 'package:tilawa/features/recitation_practice/domain/repositories/recitation_audio_verification_repository.dart';
import 'package:tilawa/features/recitation_practice/domain/repositories/recitation_verse_repository.dart';
import 'package:tilawa/features/recitation_practice/domain/usecases/get_page_recitation_targets_use_case.dart';
import 'package:tilawa/features/recitation_practice/presentation/cubit/recitation_practice_cubit.dart';
import 'package:tilawa/features/recitation_practice/presentation/cubit/recitation_practice_state.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  late _FakeRecitationVerseRepository verseRepository;
  late _FakeRecitationAudioVerificationRepository verificationRepository;
  late RecitationPracticeCubit cubit;

  setUp(() {
    verseRepository = _FakeRecitationVerseRepository();
    verificationRepository = _FakeRecitationAudioVerificationRepository();
    cubit = RecitationPracticeCubit(
      GetPageRecitationTargetsUseCase(verseRepository),
      verificationRepository,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('openForPage starts recording the first ayah target', () async {
    await cubit.openForPage(1);

    expect(cubit.state.isSessionActive, isTrue);
    expect(cubit.state.phase, RecitationPracticePhase.listening);
    expect(verificationRepository.startedTargets, <RecitationTarget>[
      _firstTarget,
    ]);
  });

  test(
    'endSession verifies recording and leaves failed ayah ready to retry',
    () async {
      verificationRepository.result = _comparison(score: 0.4);

      await cubit.openForPage(1);
      await cubit.endSession();

      expect(cubit.state.isSessionActive, isFalse);
      expect(cubit.state.phase, RecitationPracticePhase.idle);
      expect(cubit.state.comparisonResult?.score, 0.4);
      expect(cubit.state.completedTargetIndices, isEmpty);
    },
  );

  test(
    'endSession exposes verifier failures without closing the panel',
    () async {
      verificationRepository.failure = Failure.serverError(
        'Recitation verifier function was not found.',
      );

      await cubit.openForPage(1);
      await cubit.endSession();

      expect(cubit.state.isPanelOpen, isTrue);
      expect(cubit.state.isSessionActive, isFalse);
      expect(cubit.state.phase, RecitationPracticePhase.feedback);
      expect(
        cubit.state.failure?.message,
        'Recitation verifier function was not found.',
      );
    },
  );
}

const RecitationTarget _firstTarget = RecitationTarget(
  surahNumber: 1,
  ayahNumber: 1,
  pageNumber: 1,
  displayText: 'بسم الله الرحمن الرحيم',
  normalText: 'بسم الله الرحمن الرحيم',
);

RecitationComparisonResult _comparison({required double score}) {
  return RecitationComparisonResult(
    score: score,
    spokenText: '',
    words: const <ComparedWord>[
      ComparedWord(word: 'بسم', status: WordMatchStatus.correct),
    ],
  );
}

class _FakeRecitationVerseRepository implements RecitationVerseRepository {
  @override
  List<RecitationTarget> getTargetsForPage(int pageNumber) {
    return const <RecitationTarget>[_firstTarget];
  }
}

class _FakeRecitationAudioVerificationRepository
    implements RecitationAudioVerificationRepository {
  final List<RecitationTarget> startedTargets = <RecitationTarget>[];
  RecitationComparisonResult result = _comparison(score: 1);
  Failure? failure;

  @override
  Future<Either<Failure, void>> startRecording(RecitationTarget target) async {
    startedTargets.add(target);
    return const Right(null);
  }

  @override
  Future<Either<Failure, RecitationComparisonResult>> stopAndVerify(
    RecitationTarget target,
  ) async {
    final Failure? currentFailure = failure;
    if (currentFailure != null) {
      return Left(currentFailure);
    }
    return Right(result);
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}
