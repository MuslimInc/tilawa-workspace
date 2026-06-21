import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/get_teachers_usecase.dart';
import '../helpers/fakes/fake_teacher_repository.dart';
import '../helpers/fixtures.dart';

void main() {
  late FakeTeacherRepository repo;
  late GetTeachersUseCase useCase;

  setUp(() {
    repo = FakeTeacherRepository();
    useCase = GetTeachersUseCase(repo);
  });

  group('GetTeachersUseCase', () {
    test('returns all teachers when no filter applied', () async {
      repo.teachers = [makeTeacher(id: '1'), makeTeacher(id: '2')];

      final result = await useCase();

      result.fold(
        (f) => fail('expected Right, got $f'),
        (page) => check(page.teachers).length.equals(2),
      );
    });

    test('filters by specialization', () async {
      repo.teachers = [
        makeTeacher(id: '1', specializations: ['tajweed']),
        makeTeacher(id: '2', specializations: ['hifz']),
      ];

      final result = await useCase(specialization: 'hifz');

      result.fold(
        (f) => fail('expected Right, got $f'),
        (page) {
          check(page.teachers).length.equals(1);
          check(page.teachers.first.id).equals('2');
        },
      );
    });

    test('propagates failure from repository', () async {
      repo.failWith = const NetworkFailure();

      final result = await useCase();

      expect(result.isLeft, isTrue);
    });
  });
}
