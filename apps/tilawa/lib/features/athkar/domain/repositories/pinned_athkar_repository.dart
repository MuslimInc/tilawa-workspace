import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/pinned_athkar_preference.dart';

/// Stores the user's Home athkar shortcut preference locally.
abstract interface class PinnedAthkarRepository {
  ResultFuture<PinnedAthkarPreference> getPreference();

  ResultVoid saveCategoryIds(List<int> categoryIds);
}
