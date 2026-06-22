import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:test/test.dart';

void main() {
  group('HomePrimaryActionCubit', () {
    late HomePrimaryActionCubit cubit;

    setUp(() {
      cubit = HomePrimaryActionCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('defaults to quran when no stronger resume signal exists', () {
      cubit.recompute(
        quran: const HomeQuranResumeState(status: HomeQuranResumeStatus.ready),
        listening: const HomeListeningResumeState(),
        athkar: const HomeAthkarCompactState(status: HomeAthkarRowStatus.ready),
      );

      expect(cubit.state.kind, HomePrimaryActionKind.quran);
    });

    test('prefers listening when active and quran has no reading progress', () {
      cubit.recompute(
        quran: const HomeQuranResumeState(status: HomeQuranResumeStatus.ready),
        listening: const HomeListeningResumeState(
          status: HomeListeningResumeStatus.ready,
          reciterName: 'Mishary',
          surahName: 'Al-Fatiha',
          audioUrl: 'https://example.com/audio.mp3',
        ),
        athkar: const HomeAthkarCompactState(status: HomeAthkarRowStatus.ready),
      );

      expect(cubit.state.kind, HomePrimaryActionKind.listening);
    });

    test('prefers urgent athkar over quran when listening is not eligible', () {
      const AthkarCategory category = AthkarCategory(
        id: 1,
        nameAr: 'أذكار الصباح',
        nameEn: 'Morning Athkar',
        icon: 'wb_sunny_rounded',
      );

      cubit.recompute(
        quran: const HomeQuranResumeState(
          status: HomeQuranResumeStatus.ready,
          page: 12,
        ),
        listening: const HomeListeningResumeState(),
        athkar: const HomeAthkarCompactState(
          status: HomeAthkarRowStatus.ready,
          rows: [
            HomeAthkarRowState(
              category: category,
              completion: HomeAthkarCompletionState.inProgress,
              remainingCount: 2,
            ),
          ],
        ),
      );

      expect(cubit.state.kind, HomePrimaryActionKind.athkar);
      expect(cubit.state.urgentAthkarRow?.category.id, 1);
    });
  });
}
