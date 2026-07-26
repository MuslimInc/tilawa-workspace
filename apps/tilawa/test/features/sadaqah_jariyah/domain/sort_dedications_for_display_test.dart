import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/dedication.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/enums/dedication_status.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/usecases/sort_dedications_for_display_use_case.dart';

Dedication _d({
  required String id,
  bool founding = false,
  bool featured = false,
  int sortOrder = 0,
}) {
  return Dedication(
    id: id,
    displayName: id,
    slug: id,
    status: DedicationStatus.published,
    isFounding: founding,
    isFeatured: featured,
    sortOrder: sortOrder,
  );
}

void main() {
  test('founding before featured before rest; sortOrder within band', () {
    final List<Dedication> input = <Dedication>[
      _d(id: 'r2', sortOrder: 2),
      _d(id: 'f1', featured: true, sortOrder: 5),
      _d(id: 'founding', founding: true, sortOrder: 99),
      _d(id: 'r1', sortOrder: 1),
      _d(id: 'f0', featured: true, sortOrder: 1),
    ];

    final List<Dedication> sorted = sortDedicationsForDisplay(input);

    check(sorted.map((Dedication d) => d.id).toList()).deepEquals(<String>[
      'founding',
      'f0',
      'f1',
      'r1',
      'r2',
    ]);
  });

  test('isFounding wins over isFeatured for banding', () {
    final List<Dedication> sorted = sortDedicationsForDisplay(<Dedication>[
      _d(id: 'x', founding: true, featured: true, sortOrder: 10),
      _d(id: 'y', featured: true, sortOrder: 1),
    ]);
    check(sorted.first.id).equals('x');
  });
}
