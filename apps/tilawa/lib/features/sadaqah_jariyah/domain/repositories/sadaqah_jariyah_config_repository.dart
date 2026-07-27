import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/sadaqah_jariyah_config.dart';

abstract class SadaqahJariyahConfigRepository {
  ResultFuture<SadaqahJariyahConfig> getConfig();
}
