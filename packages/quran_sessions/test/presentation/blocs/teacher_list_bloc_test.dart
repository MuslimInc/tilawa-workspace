import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/get_teachers_usecase.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_event.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_state.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeTeacherRepository repo;
  late TeacherListBloc bloc;

  setUp(() {
    repo = FakeTeacherRepository();
    bloc = TeacherListBloc(GetTeachersUseCase(repo));
  });

  tearDown(() => bloc.close());

  group('TeacherListBloc', () {
    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Success] when teachers are returned',
      build: () {
        repo.teachers = [makeTeacher(id: '1'), makeTeacher(id: '2')];
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        check(state.teachers).length.equals(2);
        check(state.hasMore).isFalse();
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Empty] when no teachers match filter',
      build: () {
        repo.teachers = [
          makeTeacher(specializations: ['tajweed']),
        ];
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested(specialization: 'hifz')),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListEmpty>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListEmpty;
        check(state.activeSpecialization).equals('hifz');
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Failure] on repository error',
      build: () {
        repo.failWith = const NetworkFailure();
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListFailure>(),
      ],
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'LoadMoreTeachersRequested is dropped when state is not Success',
      build: () => bloc,
      act: (b) => b.add(const LoadMoreTeachersRequested()),
      expect: () => <TeacherListState>[],
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'TeacherFilterChanged re-fetches from page 1 with new filter',
      build: () {
        repo.teachers = [
          makeTeacher(specializations: ['hifz']),
        ];
        return bloc;
      },
      act: (b) => b.add(const TeacherFilterChanged(specialization: 'hifz')),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        check(state.activeSpecialization).equals('hifz');
      },
    );
  });
}
