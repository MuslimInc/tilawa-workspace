import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/dedication.dart';

abstract class DedicationsRepository {
  ResultFuture<List<Dedication>> getPublishedDedications();
}
