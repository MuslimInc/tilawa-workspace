import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  test('load emits ready state with last-read position', () async {
    final cubit = HomeQuranResumeCubit(_SuccessGetLastRead());
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.surahNumber, 2);
    expect(cubit.state.page, 42);
    expect(cubit.state.progressFraction(604), closeTo(42 / 604, 0.001));
  });

  test('load emits failure when use case fails', () async {
    final cubit = HomeQuranResumeCubit(_FailingGetLastRead());
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.failure, isNotNull);
  });
}

class _SuccessGetLastRead implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return const Right((surahNumber: 2, ayahNumber: 43, page: 42));
  }
}

class _FailingGetLastRead implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return Left(Failure.unexpectedError('storage'));
  }
}
