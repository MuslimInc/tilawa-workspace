import '../entities/dedication.dart';

/// Pure display banding: founding → featured → rest (each by sortOrder, then id).
List<Dedication> sortDedicationsForDisplay(List<Dedication> input) {
  final List<Dedication> founding = <Dedication>[];
  final List<Dedication> featured = <Dedication>[];
  final List<Dedication> rest = <Dedication>[];

  for (final Dedication d in input) {
    if (d.isFounding) {
      founding.add(d);
    } else if (d.isFeatured) {
      featured.add(d);
    } else {
      rest.add(d);
    }
  }

  int byOrder(Dedication a, Dedication b) {
    final int c = a.sortOrder.compareTo(b.sortOrder);
    if (c != 0) {
      return c;
    }
    return a.id.compareTo(b.id);
  }

  founding.sort(byOrder);
  featured.sort(byOrder);
  rest.sort(byOrder);

  return <Dedication>[...founding, ...featured, ...rest];
}
