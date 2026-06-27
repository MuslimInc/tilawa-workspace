import 'package:checks/checks.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_list_filter_logic.dart';
import 'package:test/test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('filterTeachersByNameQuery', () {
    test('returns all teachers when query is empty', () {
      final teachers = [
        makeTeacher(id: 't1', displayName: 'Sheikh Ahmed'),
        makeTeacher(id: 't2', displayName: 'Ustad Fatima'),
      ];

      check(filterTeachersByNameQuery(teachers, '')).deepEquals(teachers);
      check(filterTeachersByNameQuery(teachers, '   ')).deepEquals(teachers);
    });

    test('matches display name case-insensitively', () {
      final teachers = [
        makeTeacher(id: 't1', displayName: 'Sheikh Ahmed'),
        makeTeacher(id: 't2', displayName: 'Ustad Fatima'),
      ];

      final filtered = filterTeachersByNameQuery(teachers, 'ahmed');

      check(filtered.length).equals(1);
      check(filtered.single.id).equals('t1');
    });
  });
}
